import 'parsed_receipt.dart';

/// Pure-Dart heuristic parser. Extracts amount, date, merchant, and category
/// hint from raw OCR text. No Flutter dependencies — fully testable.
///
/// Locale assumption: Indian (₹), so ambiguous numeric dates parsed as
/// DD/MM/YYYY. Decimal separator is `.` (EU comma decimal not supported v1).
class ReceiptParser {
  ParsedReceipt parse(String rawText) {
    final amount = _extractAmount(rawText);
    final date = _extractDate(rawText);
    final merchant = _extractMerchant(rawText);
    final categoryHint = _extractCategoryHint(rawText, merchant);

    final extractedCount = [amount, date, merchant, categoryHint]
        .where((e) => e != null)
        .length;
    final confidence = extractedCount / 4.0;

    return ParsedReceipt(
      amount: amount,
      date: date,
      merchant: merchant,
      categoryHint: categoryHint,
      rawText: rawText,
      confidence: confidence,
    );
  }

  // ── Amount ─────────────────────────────────────────────────────────

  static const _priorityKeywords = [
    'grand total',
    'amount due',
    'total due',
    'balance due',
    'total payable',
    'net payable',
    'total',
    'amount',
    'to pay',
  ];

  static const _excludeKeywords = [
    'subtotal',
    'sub-total',
    'sub total',
    'tax',
    'gst',
    'vat',
    'cgst',
    'sgst',
    'service charge',
    'tip',
    'change',
    'cash',
    'tendered',
    'discount',
    'saved',
  ];

  static final _numberRegex = RegExp(
    r'(?:[₹$€£¥]\s*)?(\d{1,3}(?:[,\s]\d{3})*\.\d{1,2}|\d+\.\d{1,2}|\d+)',
  );

  double? _extractAmount(String rawText) {
    final lines = rawText.split('\n');

    // Priority pass — find lines with priority keywords, skip exclusions.
    for (final keyword in _priorityKeywords) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (!lower.contains(keyword)) continue;
        if (_excludeKeywords.any((e) => lower.contains(e))) continue;

        final amount = _extractRightmostNumber(line);
        if (amount != null && _isValidAmount(amount)) return amount;
      }
    }

    // Fallback — largest number with 2 decimals on any non-excluded line.
    double? largest;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_excludeKeywords.any((e) => lower.contains(e))) continue;

      final matches = _numberRegex.allMatches(line);
      for (final m in matches) {
        final raw = m.group(1);
        if (raw == null) continue;
        // Only consider 2-decimal numbers in fallback (real totals are formatted)
        if (!raw.contains('.')) continue;
        final parsed = _parseNumber(raw);
        if (parsed == null || !_isValidAmount(parsed)) continue;
        if (largest == null || parsed > largest) largest = parsed;
      }
    }
    return largest;
  }

  double? _extractRightmostNumber(String line) {
    final matches = _numberRegex.allMatches(line).toList();
    if (matches.isEmpty) return null;
    final raw = matches.last.group(1);
    if (raw == null) return null;
    return _parseNumber(raw);
  }

  double? _parseNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[,\s]'), '');
    return double.tryParse(cleaned);
  }

  bool _isValidAmount(double v) => v >= 0.01 && v <= 1000000;

  // ── Date ───────────────────────────────────────────────────────────

  static final _dateRegexes = [
    // ISO: YYYY-MM-DD
    RegExp(r'\b(20\d{2})-(\d{1,2})-(\d{1,2})\b'),
    // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY (locale: assume DD first)
    RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](20\d{2}|\d{2})\b'),
    // DD MMM YYYY (e.g. "5 Jan 2024")
    RegExp(
      r'\b(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(20\d{2}|\d{2})\b',
      caseSensitive: false,
    ),
    // MMM DD YYYY (e.g. "Jan 5, 2024")
    RegExp(
      r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2}),?\s+(20\d{2})\b',
      caseSensitive: false,
    ),
  ];

  static const _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  DateTime? _extractDate(String rawText) {
    final candidates = <DateTime>[];
    final now = DateTime.now();

    for (var i = 0; i < _dateRegexes.length; i++) {
      final matches = _dateRegexes[i].allMatches(rawText);
      for (final m in matches) {
        DateTime? d;
        try {
          if (i == 0) {
            // ISO
            d = DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!),
                int.parse(m.group(3)!));
          } else if (i == 1) {
            // DD/MM/YYYY (locale assumption)
            final yr = int.parse(m.group(3)!);
            final year = yr < 100 ? 2000 + yr : yr;
            d = DateTime(year, int.parse(m.group(2)!), int.parse(m.group(1)!));
          } else if (i == 2) {
            // DD MMM YYYY
            final yr = int.parse(m.group(3)!);
            final year = yr < 100 ? 2000 + yr : yr;
            final mon = _monthMap[m.group(2)!.toLowerCase().substring(0, 3)];
            if (mon == null) continue;
            d = DateTime(year, mon, int.parse(m.group(1)!));
          } else if (i == 3) {
            // MMM DD YYYY
            final mon = _monthMap[m.group(1)!.toLowerCase().substring(0, 3)];
            if (mon == null) continue;
            d = DateTime(int.parse(m.group(3)!), mon, int.parse(m.group(2)!));
          }
        } catch (_) {
          continue;
        }
        if (d == null) continue;

        // Sanity: reject future dates and dates >5 years past
        if (d.isAfter(now)) continue;
        if (d.isBefore(now.subtract(const Duration(days: 365 * 5)))) continue;

        candidates.add(d);
      }
      if (candidates.isNotEmpty) break; // first format that matches wins
    }

    if (candidates.isEmpty) return null;
    // Earliest occurrence in text wins (receipts print date near top —
    // but matches are already in order, so just return first)
    return candidates.first;
  }

  // ── Merchant ───────────────────────────────────────────────────────

  static final _phoneShapedRegex = RegExp(r'^[\d\s\-\(\)+]+$');
  static const _merchantBlocklist = [
    'gst',
    'vat',
    'tax id',
    'pan',
    'cin',
    'tel',
    'phone',
    'www.',
    'http',
    '@',
  ];

  String? _extractMerchant(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(5)
        .toList();

    final candidates = <String>[];
    for (final line in lines) {
      if (_phoneShapedRegex.hasMatch(line)) continue;

      // Skip if matches any date pattern
      if (_dateRegexes.any((r) => r.hasMatch(line))) continue;

      final lower = line.toLowerCase();
      if (_merchantBlocklist.any((b) => lower.contains(b))) continue;

      if (line.length < 3 || line.length > 40) continue;

      candidates.add(line);
    }

    if (candidates.isEmpty) {
      // Fallback: first non-empty line as-is
      return lines.isNotEmpty ? lines.first : null;
    }

    // Longest = brand line (over street address)
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return _titleCase(candidates.first);
  }

  String _titleCase(String s) {
    return s
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ── Category hint ──────────────────────────────────────────────────

  static const Map<String, List<String>> _categoryKeywords = {
    'coffee': ['starbucks', 'coffee', 'cafe', 'espresso', 'dunkin', 'costa'],
    'transport': ['uber', 'ola', 'lyft', 'taxi', 'cab', 'metro', 'train', 'bus'],
    'fuel': ['petrol', 'diesel', 'shell', 'indian oil', ' bp ', 'gas station'],
    'food': [
      'zomato',
      'swiggy',
      'mcdonald',
      'kfc',
      'pizza',
      'burger',
      'dominos',
      'restaurant',
      'dine'
    ],
    'groceries': [
      'big bazaar',
      'dmart',
      'reliance fresh',
      'grofers',
      'zepto',
      'blinkit',
      'grocery',
      'supermarket'
    ],
    'shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'mall', 'store'],
    'clothing': ['zara', 'h&m', 'nike', 'adidas', 'levis', 'apparel', 'clothing'],
    'subscriptions': [
      'netflix',
      'spotify',
      'prime video',
      'hotstar',
      'youtube premium'
    ],
    'phone': ['airtel', 'jio', 'vodafone', 'vi mobile', 'recharge'],
    'bills': ['electricity', 'water bill', 'gas bill', 'bescom', 'mseb'],
    'rent': ['rent'],
    'health': ['pharmacy', 'apollo', 'medplus', 'hospital', 'clinic', 'doctor'],
    'gym': ['gym', 'fitness', 'cult'],
    'beauty': ['sephora', 'nykaa', 'salon', 'parlour', 'spa'],
    'entertainment': [
      'pvr',
      'inox',
      'cinepolis',
      'movie',
      'theatre',
      'bookmyshow'
    ],
    'travel': [
      'airline',
      'indigo',
      'vistara',
      'spicejet',
      'hotel',
      'oyo',
      'makemytrip',
      'goibibo',
      'irctc'
    ],
    'pets': ['petsmart', ' vet ', ' pet '],
  };

  String? _extractCategoryHint(String rawText, String? merchant) {
    final haystack = ('${merchant ?? ''} '
            '${rawText.length > 200 ? rawText.substring(0, 200) : rawText}')
        .toLowerCase();

    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (haystack.contains(kw)) return entry.key;
      }
    }
    return null;
  }
}
