import 'package:flutter/material.dart';

class JarHelpers {
  static Color hexToColor(String? hex, {Color fallback = const Color(0xFF6366F1)}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;
    return Color(int.tryParse(value, radix: 16) ?? 0xFF6366F1);
  }

  static IconData iconFromName(String? name) {
    switch ((name ?? '').trim()) {
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'piggy_bank':
        return Icons.savings_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  static String formatMoney(num value, {String currency = 'VND'}) {
    final negative = value < 0;
    final digits = value.abs().round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    final suffix = currency.toUpperCase() == 'USD' ? ' USD' : ' ₫';
    return '${negative ? '-' : ''}${buffer.toString()}$suffix';
  }

  static String monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static String monthLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '$month/${date.year}';
  }
}
