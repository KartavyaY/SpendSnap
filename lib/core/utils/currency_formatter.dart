import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _usdFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compact(locale: 'en_IN');

  static String format(double amount, {String currency = 'INR'}) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return _usdFormatter.format(amount);
      case 'INR':
      default:
        return _inrFormatter.format(amount);
    }
  }

  static String formatCompact(double amount, {String currency = 'INR'}) {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : '₹';
    return '$symbol${_compactFormatter.format(amount)}';
  }

  static String formatSigned(double amount, {String currency = 'INR'}) {
    final formatted = format(amount.abs(), currency: currency);
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }
}
