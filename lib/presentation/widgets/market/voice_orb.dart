import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';

enum OrbMode { idle, listening, thinking, speaking }

/// Esfera del modo conversación (azul PayPal). Late con la voz del dueño
/// al escuchar, gira al pensar y respira al hablar.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({super.key, required this.mode, required this.level, this.size = 220});

  final OrbMode mode;

  /// Volumen del micrófono (0..1) mientras escucha.
  final ValueNotifier<double> level;
  final double size;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  double _smooth = 0;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_clock, widget.level]),
        builder: (context, _) {
          final t = _clock.value * 2 * math.pi;
          final target = widget.mode == OrbMode.listening ? widget.level.value : 0.0;
          // Suaviza el volumen para que no tiemble.
          _smooth += (target - _smooth) * 0.25;

          final scale = switch (widget.mode) {
            OrbMode.listening => 1 + _smooth * 0.28,
            OrbMode.speaking => 1 + 0.05 * math.sin(t * 4) + 0.03 * math.sin(t * 7),
            OrbMode.thinking => 0.94 + 0.02 * math.sin(t * 3),
            OrbMode.idle => 0.9,
          };

          return SizedBox(
            width: widget.size * 1.35,
            height: widget.size * 1.35,
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _OrbPainter(
                    phase: t,
                    mode: widget.mode,
                    accent: p.accent,
                    navy: p.navy,
                    light: p.accentLight,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.phase,
    required this.mode,
    required this.accent,
    required this.navy,
    required this.light,
  });

  final double phase;
  final OrbMode mode;
  final Color accent;
  final Color navy;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final dim = mode == OrbMode.idle ? 0.55 : 1.0;

    // Halo.
    canvas.drawCircle(
      center,
      radius * 1.18,
      Paint()
        ..color = accent.withValues(alpha: 0.14 * dim)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25),
    );

    // Cuerpo con degradado que se mueve despacio.
    final focal = Offset(math.cos(phase) * 0.35, math.sin(phase * 1.3) * 0.35);
    final body = Paint()
      ..shader = RadialGradient(
        center: Alignment(focal.dx, focal.dy),
        radius: 1.05,
        colors: [
          Color.lerp(light, Colors.white, 0.35)!.withValues(alpha: dim),
          accent.withValues(alpha: dim),
          navy.withValues(alpha: dim),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, body);

    // Brillos internos.
    for (var i = 0; i < 3; i++) {
      final a = phase * (1 + i * 0.4) + i * 2.1;
      final o = center + Offset(math.cos(a), math.sin(a * 1.2)) * radius * 0.38;
      canvas.drawCircle(
        o,
        radius * (0.32 - i * 0.06),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10 * dim)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
      );
    }

    // Al pensar, un anillo gira alrededor.
    if (mode == OrbMode.thinking) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [accent.withValues(alpha: 0), Colors.white.withValues(alpha: 0.9)],
          transform: GradientRotation(phase * 3),
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.12));
      canvas.drawCircle(center, radius * 1.12, ring);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => true;
}
