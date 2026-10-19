import 'package:flutter/material.dart';

/// Colores del diseño Restock (estilo Apple + azul PayPal).
///
/// Tiene versión clara y oscura para respetar el ThemeCubit de la app.
/// Se usa con `context.rp` (colores) y `context.rt` (textos).
class RestockPalette {
  const RestockPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.separator,
    required this.fill,
    required this.ink,
    required this.inkSecondary,
    required this.chevron,
    required this.navIdle,
    required this.navGlass,
    required this.accent,
    required this.onAccent,
    required this.navy,
    required this.blueSoft,
    required this.blueLight,
    required this.banner,
    required this.onBanner,
    required this.onBannerSecondary,
    required this.warning,
    required this.warningSoft,
    required this.warningBar,
    required this.transit,
    required this.transitSoft,
    required this.neutralBar,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color separator;
  final Color fill;
  final Color ink;
  final Color inkSecondary;
  final Color chevron;
  final Color navIdle;
  final Color navGlass;

  /// Azul PayPal: botones, anillo, pestaña activa.
  final Color accent;
  final Color onAccent;

  /// Azul marino PayPal: textos destacados y "ya gastado".
  final Color navy;
  final Color blueSoft;
  final Color blueLight;

  /// Tarjeta oscura destacada ("¿Ha llegado un pedido?").
  final Color banner;
  final Color onBanner;
  final Color onBannerSecondary;

  final Color warning;
  final Color warningSoft;
  final Color warningBar;
  final Color transit;
  final Color transitSoft;
  final Color neutralBar;
  final Color shadow;

  static const light = RestockPalette(
    background: Color(0xFFFBFCFE),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE9EDF4),
    separator: Color(0xFFEEF1F6),
    fill: Color(0xFFF1F3F8),
    ink: Color(0xFF0B1A33),
    inkSecondary: Color(0xFF5B6478),
    chevron: Color(0xFFA7AEBD),
    navIdle: Color(0xFF22304A),
    navGlass: Color(0xBFFFFFFF),
    accent: Color(0xFF0070E0),
    onAccent: Color(0xFFFFFFFF),
    navy: Color(0xFF003087),
    blueSoft: Color(0xFFE6F0FC),
    blueLight: Color(0xFF6FAAF0),
    banner: Color(0xFF003087),
    onBanner: Color(0xFFFFFFFF),
    onBannerSecondary: Color(0xFFC9D6EE),
    warning: Color(0xFFB45309),
    warningSoft: Color(0xFFFDF0E1),
    warningBar: Color(0xFFD97706),
    transit: Color(0xFF0E7490),
    transitSoft: Color(0xFFE0F2F5),
    neutralBar: Color(0xFF8F98AA),
    shadow: Color(0x1F003087),
  );

  static const dark = RestockPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    border: Color(0xFF2C2C2E),
    separator: Color(0xFF38383A),
    fill: Color(0xFF2C2C2E),
    ink: Color(0xFFF5F5F7),
    inkSecondary: Color(0xFFA1A1A6),
    chevron: Color(0xFF636366),
    navIdle: Color(0xFFD1D1D6),
    navGlass: Color(0xB82C2C2E),
    accent: Color(0xFF2F8CFF),
    onAccent: Color(0xFFFFFFFF),
    navy: Color(0xFF9DC2FF),
    blueSoft: Color(0xFF10264A),
    blueLight: Color(0xFF5A8FD6),
    banner: Color(0xFF0B2A66),
    onBanner: Color(0xFFFFFFFF),
    onBannerSecondary: Color(0xFFB3C6EA),
    warning: Color(0xFFFFB35C),
    warningSoft: Color(0xFF3A2A12),
    warningBar: Color(0xFFFF9F0A),
    transit: Color(0xFF5ED3E8),
    transitSoft: Color(0xFF0F2F36),
    neutralBar: Color(0xFF8E8E93),
    shadow: Color(0x80000000),
  );
}

/// Estilos de texto tipo iOS. Sin fontFamily: en iPhone sale San Francisco.
class RestockText {
  const RestockText(this.p);

  final RestockPalette p;

  TextStyle get largeTitle => TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: p.ink,
      );
  TextStyle get title2 => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: p.ink,
      );
  TextStyle get title3 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: p.ink,
      );
  TextStyle get headline =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: p.ink);
  TextStyle get body => TextStyle(fontSize: 16, color: p.ink);
  TextStyle get callout => TextStyle(fontSize: 15, color: p.ink, height: 1.45);
  TextStyle get subhead => TextStyle(fontSize: 15, color: p.inkSecondary);
  TextStyle get footnote => TextStyle(fontSize: 13, color: p.inkSecondary);
  TextStyle get caption => TextStyle(fontSize: 12, color: p.inkSecondary);
  TextStyle get overline => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: p.inkSecondary,
      );
  TextStyle get amount => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: p.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

extension RestockThemeX on BuildContext {
  RestockPalette get rp => Theme.of(this).brightness == Brightness.dark
      ? RestockPalette.dark
      : RestockPalette.light;

  RestockText get rt => RestockText(rp);
}

/// Decoración de campo de texto sin bordes, para no heredar los bordes
/// redondeados grandes del tema general de la app.
InputDecoration restockPlainInput(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: context.rp.inkSecondary,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.w400,
    ),
    filled: false,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 10),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
  );
}
