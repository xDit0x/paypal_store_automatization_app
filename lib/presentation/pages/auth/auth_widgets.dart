import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:store_automatization_app/core/configs/assets/app_assets.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';

/// Marca de la app: el icono real de Restock, recortado como una teja.
class RBrandMark extends StatelessWidget {
  const RBrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final radius = BorderRadius.circular(size * 0.3);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: p.accent.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          AppAssets.logo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          // Debajo ya está el texto "Restock": no hace falta que el lector
          // de pantalla lo diga dos veces.
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Campo de formulario con etiqueta y sin borde, como el resto de la app.
class RAuthField extends StatelessWidget {
  const RAuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofocus = false,
    this.obscure = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.footnote.copyWith(color: p.inkSecondary)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                obscureText: obscure,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                cursorColor: p.accent,
                style: t.title3.copyWith(fontSize: 17, fontWeight: FontWeight.w500),
                decoration: restockPlainInput(context, hint ?? ''),
              ),
            ),
            ...?suffix == null ? null : [suffix!],
          ],
        ),
      ],
    );
  }
}

/// Campo de contraseña con el botón de mostrar/ocultar.
class RAuthPasswordField extends StatefulWidget {
  const RAuthPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<RAuthPasswordField> createState() => _RAuthPasswordFieldState();
}

class _RAuthPasswordFieldState extends State<RAuthPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return RAuthField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      obscure: _hidden,
      suffix: Semantics(
        button: true,
        label: _hidden
            ? context.l10n.semanticsShowPassword
            : context.l10n.semanticsHidePassword,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _hidden = !_hidden),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Icon(
              _hidden ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              size: 20,
              color: p.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Enlace de texto en azul, para acciones secundarias.
class RTextLink extends StatelessWidget {
  const RTextLink(this.label, {super.key, required this.onTap, this.style});

  final String label;
  final VoidCallback? onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style:
                style ??
                TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.accent,
                ),
          ),
        ),
      ),
    );
  }
}
