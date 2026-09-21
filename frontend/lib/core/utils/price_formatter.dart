import 'package:intl/intl.dart';

class PriceFormatter {
  PriceFormatter._();

  static String formatINR(num amount) {
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return '₹${cr.toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      final lakh = amount / 100000;
      return '₹${lakh.toStringAsFixed(2)} Lakh';
    } else {
      final format = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      return format.format(amount);
    }
  }

  static String formatKm(num km) {
    final format = NumberFormat.decimalPattern('en_IN');
    return '${format.format(km)} km';
  }

  static String formatRange(num min, num max) {
    return '${formatINR(min)} - ${formatINR(max)}';
  }
}
