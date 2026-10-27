import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:store_automatization_app/common/helpers/restock_markdown.dart';
import 'package:store_automatization_app/core/audio/restock_sounds.dart';
import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
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
  const RLargeTitle(
    this.title, {
    super.key,
    this.overline,
    this.subtitle,
    this.trailing,
  });

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
                  Text(
                    overline!.toUpperCase(),
                    style: t.overline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
  const RSectionTitle(
    this.text, {
    super.key,
    this.small = false,
    this.trailing,
  });

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
          Expanded(
            child: Text(
              small ? text.toUpperCase() : text,
              style: small ? t.overline : t.title3,
            ),
          ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class RChevron extends StatelessWidget {
  const RChevron({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    CupertinoIcons.chevron_right,
    size: 16,
    color: color ?? context.rp.chevron,
  );
}

class RLevelBar extends StatelessWidget {
  const RLevelBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 5,
  });

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
      label: context.l10n.semanticsBackTo(label),
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
  const RPrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.loading = false,
  });

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
        onPressed: loading ? null : _tapThen(onPressed),
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.accent.withValues(alpha: 0.4),
          disabledForegroundColor: p.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: p.onAccent,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class RSecondaryButton extends StatelessWidget {
  const RSecondaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.color,
  });

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
        onPressed: _tapThen(onPressed),
        style: TextButton.styleFrom(
          backgroundColor: p.fill,
          foregroundColor: color ?? p.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: row,
      ),
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
            child: Icon(
              icon,
              size: size * 0.48,
              color: filled ? p.onAccent : p.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para estados vacíos o de error.
class REmptyState extends StatelessWidget {
  const REmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

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

enum RSnackTone { success, info, warning }

/// Tiempo en pantalla del aviso: 5 s de base y algo más si el texto es
/// largo, para que se pueda leer sin prisa (tope de 12 s).
Duration _snackDuration(String message) {
  const base = Duration(seconds: 5);
  const extraPerBlock = Duration(milliseconds: 1200);
  const max = Duration(seconds: 12);
  final blocks = (message.length / 90).ceil();
  final total = base + extraPerBlock * (blocks > 1 ? blocks - 1 : 0);
  return total > max ? max : total;
}

/// Aviso flotante con icono y, opcionalmente, título. Sube por encima del dock.
void showRestockSnack(
  BuildContext context,
  String message, {
  String? title,
  RSnackTone tone = RSnackTone.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final p = context.rp;
  final t = context.rt;

  RestockSounds.instance.play(switch (tone) {
    RSnackTone.success => RSound.success,
    RSnackTone.warning => RSound.warning,
    RSnackTone.info => RSound.message,
  });

  final (Color foreground, Color background, IconData icon) = switch (tone) {
    RSnackTone.success => (
      p.success,
      p.successSoft,
      CupertinoIcons.checkmark_circle_fill,
    ),
    RSnackTone.warning => (
      p.warning,
      p.warningSoft,
      CupertinoIcons.exclamationmark_triangle_fill,
    ),
    RSnackTone.info => (p.navy, p.blueSoft, CupertinoIcons.info_circle_fill),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        // Los mensajes largos del agente necesitan más tiempo para leerse.
        duration: _snackDuration(message),
        content: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: p.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(title, style: t.headline.copyWith(color: p.ink)),
                      const SizedBox(height: 2),
                    ],
                    Text.rich(
                      TextSpan(
                        children: buildInlineMarkdown(
                          message,
                          (title == null ? t.subhead : t.footnote).copyWith(
                            color: title == null ? p.ink : p.inkSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 34,
                            child: FilledButton(
                              onPressed: () {
                                RestockSounds.instance.play(RSound.tap);
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                onAction();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: p.accent,
                                foregroundColor: p.onAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(actionLabel),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

/// Pulsa con sonido: el toque suena y después corre la acción del botón.
VoidCallback? _tapThen(VoidCallback? action) {
  if (action == null) return null;
  return () {
    RestockSounds.instance.play(RSound.tap);
    action();
  };
}
