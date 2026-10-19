import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';

/// Tarjeta con borde fino y sombra suave (o color de relleno si se indica).
class RCard extends StatelessWidget {
  const RCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: color == null ? Border.all(color: p.border) : null,
        boxShadow: color == null
            ? [
                BoxShadow(
                  color: p.ink.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Lista agrupada al estilo iOS.
class RInsetGroup extends StatelessWidget {
  const RInsetGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return RCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Divider(height: 1, thickness: 1, color: p.separator),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RLargeTitle extends StatelessWidget {
  const RLargeTitle(this.title, {super.key, this.overline, this.subtitle, this.trailing});

  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(overline!.toUpperCase(), style: t.overline, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(title, style: t.largeTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: t.subhead),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class RSectionTitle extends StatelessWidget {
  const RSectionTitle(this.text, {super.key, this.small = false, this.trailing});

  final String text;
  final bool small;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(small ? text.toUpperCase() : text, style: small ? t.overline : t.title3)),
          ?trailing,
        ],
      ),
    );
  }
}

enum RPillTone { warning, transit, info, neutral }

/// Cápsula de estado: "Bajo mínimo", "En camino"...
class RPill extends StatelessWidget {
  const RPill(this.text, {super.key, this.tone = RPillTone.neutral});

  final String text;
  final RPillTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final (fg, bg) = switch (tone) {
      RPillTone.warning => (p.warning, p.warningSoft),
      RPillTone.transit => (p.transit, p.transitSoft),
      RPillTone.info => (p.navy, p.blueSoft),
      RPillTone.neutral => (p.inkSecondary, p.fill),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class RChevron extends StatelessWidget {
  const RChevron({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Icon(CupertinoIcons.chevron_right, size: 16, color: color ?? context.rp.chevron);
}

class RLevelBar extends StatelessWidget {
  const RLevelBar({super.key, required this.value, required this.color, this.height = 5});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          color: color,
          backgroundColor: context.rp.fill,
        ),
      ),
    );
  }
}

/// "‹ Atrás" al estilo iOS.
class RBackLink extends StatelessWidget {
  const RBackLink(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      button: true,
      label: 'Volver a $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.chevron_back, color: p.accent, size: 24),
              Text(label, style: TextStyle(fontSize: 17, color: p.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class RPrimaryButton extends StatelessWidget {
  const RPrimaryButton(this.label, {super.key, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.accent.withValues(alpha: 0.4),
          disabledForegroundColor: p.onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: p.onAccent),
              )
            : Text(label),
      ),
    );
  }
}

class RSecondaryButton extends StatelessWidget {
  const RSecondaryButton(this.label, {super.key, required this.onPressed, this.color});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: p.fill,
          foregroundColor: color ?? p.navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Fila de lista: título y subtítulo a la izquierda, algo a la derecha.
class RListRow extends StatelessWidget {
  const RListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.bold = false,
  });

  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = context.rt;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: bold ? t.headline : t.body),
                if (subtitle != null) ...[const SizedBox(height: 2), subtitle!],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: row),
    );
  }
}

/// Botón redondo con icono (añadir, enviar...).
class RRoundIconButton extends StatelessWidget {
  const RRoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? p.accent : p.blueSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.48, color: filled ? p.onAccent : p.accent),
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para estados vacíos o de error.
class REmptyState extends StatelessWidget {
  const REmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: p.chevron),
          const SizedBox(height: 12),
          Text(title, style: t.headline, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, style: t.footnote, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

void showRestockSnack(BuildContext context, String message) {
  final p = context.rp;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: p.background, fontSize: 15)),
        backgroundColor: p.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      ),
    );
}
