import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Lazy getter — dibuat saat pertama kali dipakai, bukan saat class dimuat
  static NumberFormat get _formatter => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

  static NumberFormat get _compact => NumberFormat.compactCurrency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 1,
      );

  static String format(double amount) {
    try {
      return _formatter.format(amount);
    } catch (_) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  static String formatCompact(double amount) {
    try {
      if (amount >= 1000000) return _compact.format(amount);
      return format(amount);
    } catch (_) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  static String formatWithoutSymbol(double amount) {
    try {
      return NumberFormat('#,###', 'id_ID').format(amount);
    } catch (_) {
      return amount.toStringAsFixed(0);
    }
  }

  static double? parse(String text) {
    try {
      final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
      return double.tryParse(clean);
    } catch (_) {
      return null;
    }
  }
}

class DateFormatter {
  // Lazy getters — aman karena locale sudah diinit di main()
  static DateFormat get _full => DateFormat('dd MMMM yyyy', 'id_ID');
  static DateFormat get _short => DateFormat('dd/MM/yyyy', 'id_ID');
  static DateFormat get _monthYear => DateFormat('MMMM yyyy', 'id_ID');
  static DateFormat get _dayMonth => DateFormat('dd MMM', 'id_ID');
  static DateFormat get _time => DateFormat('HH:mm', 'id_ID');
  static DateFormat get _fileName => DateFormat('yyyyMMdd');

  static String formatFull(DateTime date) {
    try { return _full.format(date); } catch (_) { return date.toString(); }
  }

  static String formatShort(DateTime date) {
    try { return _short.format(date); } catch (_) { return date.toString(); }
  }

  static String formatMonthYear(DateTime date) {
    try { return _monthYear.format(date); } catch (_) { return date.toString(); }
  }

  static String formatDayMonth(DateTime date) {
    try { return _dayMonth.format(date); } catch (_) { return date.toString(); }
  }

  static String formatTime(DateTime date) {
    try { return _time.format(date); } catch (_) { return ''; }
  }

  static String formatFileName(DateTime date) {
    try { return _fileName.format(date); } catch (_) { return date.millisecondsSinceEpoch.toString(); }
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    return formatShort(date);
  }

  static String getDayName(DateTime date) {
    try {
      return DateFormat('EEEE', 'id_ID').format(date);
    } catch (_) {
      return '';
    }
  }
}
