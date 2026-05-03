import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../domain/parsed_receipt.dart';
import '../domain/receipt_parser.dart';

/// Sends OCR text to Groq (Llama) for structured extraction.
/// Falls back to local heuristic [ReceiptParser] on any error.
class GroqReceiptParser {
  static const _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  final ReceiptParser _fallback;

  GroqReceiptParser(this._fallback);

  static const _allowedCategories = [
    'coffee', 'transport', 'fuel', 'food', 'groceries', 'shopping',
    'clothing', 'subscriptions', 'phone', 'bills', 'rent', 'health',
    'gym', 'beauty', 'entertainment', 'travel', 'pets', 'other',
  ];

  static const _systemPrompt = '''
You extract structured data from receipt OCR text. The receipt is always a consumer purchase — never a salary slip or income document.

Rules:
- "totalAmount": the single final amount the customer paid. Pick "Grand Total", "Amount Due", "Total Payable", or "Net Payable". Ignore subtotals, tax lines, discounts, and change given. Strip currency symbols. Return as a plain number (e.g. 348.00). null if not found.
- "date": the transaction date as YYYY-MM-DD. Dates are in Indian format DD/MM/YYYY when ambiguous. Reject future dates. null if not found.
- "vendorName": the store or business name. Short, clean, title-cased. Ignore addresses, phone numbers, GST numbers. null if not found.
- "items": array of purchased item names (strings only — no quantities, no prices, no SKUs). Clean, title-cased, deduplicated. Cap at 6 most representative items. Drop generic OCR noise like "TAX", "TOTAL", "ROUND OFF", "DISCOUNT", "CGST", "SGST". Empty array if nothing found.
- "category": pick the single best match for what was bought, using the items list as the primary signal and the vendor as secondary. Choose from — coffee, transport, fuel, food, groceries, shopping, clothing, subscriptions, phone, bills, rent, health, gym, beauty, entertainment, travel, pets, other. Use "other" when nothing fits. Never return a value outside this list.

Output format — one JSON object, nothing else:
{"vendorName":"...","date":"YYYY-MM-DD","totalAmount":0.00,"items":["...","..."],"category":"..."}''';

  Future<ParsedReceipt> parse(String rawText) async {
    if (rawText.trim().isEmpty) {
      return _fallback.parse(rawText);
    }

    // Fallback if key missing in .env
    if (_apiKey.isEmpty) {
      return _fallback.parse(rawText);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {
                  'role': 'user',
                  'content':
                      'Extract from this receipt OCR text:\n\n$rawText',
                },
              ],
              'temperature': 0,
              'max_tokens': 1200,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return _fallback.parse(rawText);
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          (body['choices'] as List).first['message']['content'] as String;

      return _parseGroqResponse(content.trim(), rawText);
    } catch (_) {
      // Network error, timeout, parse error → silent fallback
      return _fallback.parse(rawText);
    }
  }

  /// Returns null for empty strings or sentinel values like "null", "n/a", "none".
  static String? _cleanString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (lower == 'null' || lower == 'n/a' || lower == 'na' ||
        lower == 'none' || lower == 'unknown' || lower == '-') {
      return null;
    }
    return trimmed;
  }

  ParsedReceipt _parseGroqResponse(String content, String rawText) {
    try {
      // Strip markdown code fences if model wraps in ```json
      final cleaned = content
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      // Amount — sanity-checked: positive, under 1M
      double? amount = switch (json['totalAmount']) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (amount != null && (amount <= 0 || amount > 1000000)) {
        amount = null;
      }

      // Date — sanity-checked: not future, not before 2020
      DateTime? date;
      if (json['date'] is String) {
        date = DateTime.tryParse(json['date'] as String);
        if (date != null) {
          final now = DateTime.now();
          final tooOld = date.isBefore(DateTime(2020));
          final inFuture = date.isAfter(now.add(const Duration(days: 1)));
          if (tooOld || inFuture) date = null;
        }
      }

      // Merchant — null out if empty or sentinel "null"/"n/a"/"none"
      final vendor = _cleanString(json['vendorName']);

      // Items — list of clean strings, cap at 6, drop sentinels
      final items = <String>[];
      if (json['items'] is List) {
        for (final e in json['items'] as List) {
          final cleaned = _cleanString(e);
          if (cleaned != null && !items.contains(cleaned)) {
            items.add(cleaned);
            if (items.length >= 6) break;
          }
        }
      }

      // Compose a descriptive merchant/note: "Vendor · item1, item2"
      final String? merchant;
      if (vendor != null && items.isNotEmpty) {
        merchant = '$vendor · ${items.join(", ")}';
      } else if (vendor != null) {
        merchant = vendor;
      } else if (items.isNotEmpty) {
        merchant = items.join(', ');
      } else {
        merchant = null;
      }

      // Category — preserve null when model couldn't find one;
      // only default to "other" if model returned an out-of-list value.
      final rawCategory = _cleanString(json['category'])?.toLowerCase();
      final String? category;
      if (rawCategory == null || rawCategory.isEmpty) {
        category = null;
      } else if (_allowedCategories.contains(rawCategory)) {
        category = rawCategory;
      } else {
        category = 'other';
      }

      // Confidence — fraction of 4 fields actually extracted
      final extractedCount =
          [amount, date, merchant, category].where((e) => e != null).length;
      final confidence = extractedCount / 4.0;

      return ParsedReceipt(
        amount: amount,
        date: date,
        merchant: merchant,
        categoryHint: category,
        rawText: rawText,
        confidence: confidence,
      );
    } catch (_) {
      return _fallback.parse(rawText);
    }
  }
}
