import 'package:equatable/equatable.dart';

/// Data passed from the receipt-scan flow to AddTransactionPage via
/// GoRouter `extra`. All fields nullable — parser does best-effort
/// extraction and user can edit/fill anything missing.
class ReceiptPrefill extends Equatable {
  /// Extracted amount (positive value).
  final double? amount;

  /// Extracted transaction date.
  final DateTime? date;

  /// Extracted merchant name — used as the note field.
  final String? merchant;

  /// CategoryIcon key (e.g. "coffee", "groceries"). Matches stable
  /// `CategoryModel.icon` values, not display names.
  final String? categoryHint;

  const ReceiptPrefill({
    this.amount,
    this.date,
    this.merchant,
    this.categoryHint,
  });

  @override
  List<Object?> get props => [amount, date, merchant, categoryHint];
}
