import 'package:intl/intl.dart';

class AppHelpers {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    decimalDigits: 2,
  );
  
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');
  
  static String formatCurrency(double amount, String currency) {
    final format = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: currency,
      decimalDigits: 2,
    );
    return format.format(amount);
  }
  
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }
  
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${_getPluralForm(weeks, 'неделю', 'недели', 'недель')} назад';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${_getPluralForm(months, 'месяц', 'месяца', 'месяцев')} назад';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${_getPluralForm(years, 'год', 'года', 'лет')} назад';
    }
  }
  
  static String _getPluralForm(int number, String form1, String form2, String form5) {
    final absNumber = number.abs();
    if (absNumber % 10 == 1 && absNumber % 100 != 11) {
      return form1;
    } else if (absNumber % 10 >= 2 && absNumber % 10 <= 4 && (absNumber % 100 < 10 || absNumber % 100 >= 20)) {
      return form2;
    } else {
      return form5;
    }
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPhone(String phone) {
    // Удаляем все символы кроме цифр
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Проверяем что это российский номер (10 или 11 цифр)
    return digits.length >= 10 && digits.length <= 11;
  }
  
  static String formatPhone(String phone) {
    // Удаляем все символы кроме цифр
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 11) {
      // Формат +7 (XXX) XXX-XX-XX
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9, 11)}';
    } else if (digits.length == 10) {
      // Формат (XXX) XXX-XX-XX
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 8)}-${digits.substring(8, 10)}';
    }
    
    return phone;
  }
  
  static double roundToTwo(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
  
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  static String generateFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = baseName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '$sanitizedName_$timestamp$extension';
  }
  
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }
  
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
