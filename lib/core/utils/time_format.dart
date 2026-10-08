import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Small formatting helpers used across screens.
class TimeFormat {
  TimeFormat._();

  /// "05:42" in the device locale.
  static String hm(BuildContext context, DateTime time) {
    try {
      return TimeOfDay.fromDateTime(time).format(context);
    } catch (_) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
  }

  /// "1h 23m" style countdown.
  static String countdown(Duration d) {
    if (d.isNegative) return '0m';
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    final int seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  /// "Thursday, 8 October 2026" (best effort with locale).
  static String gregorian(DateTime date, String localeCode) {
    try {
      return DateFormat.yMMMMEEEEd(localeCode).format(date);
    } catch (_) {
      try {
        return DateFormat.yMMMMEEEEd('en').format(date);
      } catch (_) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }
}
