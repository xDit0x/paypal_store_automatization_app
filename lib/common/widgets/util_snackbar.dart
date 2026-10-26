import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum UtilSnackbarType {
  ok(Colors.green, Icons.check_rounded),
  warning(Color(0xFFFF8F00), Icons.warning_amber_rounded),
  bad(Colors.red, Icons.error_outline);

  final Color color;
  final IconData icon;
  const UtilSnackbarType(this.color, this.icon);
}

class UtilSnackbar {
  const UtilSnackbar._();

  static String? _activeKey;

  static void show(
    BuildContext context,
    String message, {
    UtilSnackbarType selection = UtilSnackbarType.bad,
  }) {
    final key = '${selection.name}|$message';

    if (_activeKey == key) return;

    final messenger = ScaffoldMessenger.of(context);
    _activeKey = key;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(selection.icon, color: Colors.white, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: selection.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      ).closed.then((_) {
        if (_activeKey == key) _activeKey = null;
      });
  }
}
