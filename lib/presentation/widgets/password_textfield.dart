import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';

class PasswordTxtField extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  const PasswordTxtField({
    super.key,
    required this.controller,
    this.hint,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<PasswordTxtField> createState() => _PasswordTxtFieldState();
}

class _PasswordTxtFieldState extends State<PasswordTxtField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      cursorHeight: 18.h,
      cursorWidth: 6.w,
      cursorRadius: const Radius.circular(50),
      decoration: InputDecoration(
        hintText: widget.hint ?? context.l10n.authPassword,
        hintStyle: TextStyle(
          fontSize: 13.sp,
          color: scheme.onSurface.withValues(alpha: 0.55),
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureText = !_obscureText),
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}
