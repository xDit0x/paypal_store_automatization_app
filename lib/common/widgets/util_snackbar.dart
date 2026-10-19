import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum UtilSnackbarType {
  ok(Colors.green, Icons.check_rounded),
  warning(Colors.amber, Icons.warning_amber_rounded),
  bad(Colors.red, Icons.error_outline);

  final Color color;
  final IconData icon;
  const UtilSnackbarType(this.color, this.icon);
}

class UtilSnackbar {
  const UtilSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    UtilSnackbarType selection = UtilSnackbarType.bad,
  }) {
    ScaffoldMessenger.of(context)
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
      );
  }
}
