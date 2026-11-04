import 'package:flutter/material.dart';

/// Importe "contador": al aparecer sube rápidamente de 0 al valor, y cuando
/// el valor cambia (por ejemplo tras pagar un pedido) anima desde el importe
/// que se estaba mostrando hasta el nuevo.
///
/// Con las animaciones desactivadas (accesibilidad) muestra el valor final
/// directamente.
class AnimatedAmount extends StatefulWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
  });

  /// Valor final que se quiere mostrar.
  final double value;

  /// Construye la interfaz con el valor animado del momento.
  final Widget Function(BuildContext context, double value) builder;

  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late Animation<double> _animation;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _start(from: 0);
  }

  @override
  void didUpdateWidget(covariant AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.value != _to) {
      _start(from: _shown);
    }
  }

  /// Importe que se está viendo ahora mismo.
  double get _shown => _controller.isAnimating ? _animation.value : _to;

  void _start({required double from}) {
    _to = widget.value;
    _animation = Tween<double>(begin: from, end: _to).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.builder(context, widget.value);
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => widget.builder(context, _animation.value),
    );
  }
}
