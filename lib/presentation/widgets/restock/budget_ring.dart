import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';

/// Anillo de presupuesto al estilo de los anillos de actividad de Apple.
class BudgetRing extends StatelessWidget {
  const BudgetRing({super.key, required this.progress, this.size = 84});

  /// Entre 0 y 1.
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final value = progress.clamp(0, 1).toDouble();
    return Semantics(
      label: '${(value * 100).round()} % del presupuesto usado',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(progress: v, track: p.blueSoft, color: value >= 0.9 ? p.warningBar : p.accent),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.color});

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.125;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (progress <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
