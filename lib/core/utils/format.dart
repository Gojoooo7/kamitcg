import 'package:intl/intl.dart';

/// Helpers de formatage — équivalents Flutter de fmtMoney / fmtPct du design.
class Format {
  const Format._();

  static final NumberFormat _money =
      NumberFormat.currency(locale: 'en_US', symbol: '€', decimalDigits: 2);
  static final NumberFormat _moneyNoSign =
      NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);
  static final NumberFormat _intGrouped = NumberFormat.decimalPattern('en_US');

  /// `€1,248.00` (sans signe) ou `+ €120.00` / `− €12.00` (avec sign:true).
  static String money(double value, {bool sign = false}) {
    if (!sign) return _money.format(value);
    final v = _moneyNoSign.format(value.abs()).trim();
    return '${value >= 0 ? '+ ' : '− '}€$v';
  }

  /// `+2.91%` / `−1.20%`
  static String pct(double value) {
    final s = value.toStringAsFixed(2);
    if (value > 0) return '+$s%';
    return '$s%';
  }

  /// Formate un entier avec séparateurs : `1,248`
  static String intGrouped(num value) => _intGrouped.format(value);
}
