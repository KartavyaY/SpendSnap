import 'package:equatable/equatable.dart';

/// Result of OCR + heuristic parsing of a receipt photo.
///
/// All extraction fields are nullable — parser returns whatever it can
/// find, user reviews and fills in the rest.
class ParsedReceipt extends Equatable {
  /// Best guess at total amount (e.g. 1234.56). Null if no candidate found.
  final double? amount;

  /// Best guess at transaction date.
  final DateTime? date;

  /// Best guess at merchant/vendor name.
  final String? merchant;

  /// Suggested category key (matches CategoryIcon keys), based on keyword
  /// heuristics over OCR text. May be null if no keyword matched.
  final String? categoryHint;

  /// Raw OCR text. Useful for debug + user manual fallback.
  final String rawText;

  /// Parser confidence in extracted fields (0-1). Computed as the fraction
  /// of (amount, date, merchant, categoryHint) that were successfully
  /// extracted.
  final double confidence;

  const ParsedReceipt({
    this.amount,
    this.date,
    this.merchant,
    this.categoryHint,
    required this.rawText,
    this.confidence = 0,
  });

  bool get hasAmount => amount != null && amount! > 0;

  @override
  List<Object?> get props =>
      [amount, date, merchant, categoryHint, rawText, confidence];
}
