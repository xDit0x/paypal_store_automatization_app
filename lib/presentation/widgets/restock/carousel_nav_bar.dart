import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';

class NavItem {
  const NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Barra inferior con las cinco pestañas siempre visibles. La activa se
/// agranda y las demás se reducen. Incluye una píldora azul que se desliza
/// siguiendo el dedo y se asienta en la pestaña elegida.
///
/// Va enganchada al [PageController] de las pantallas para mantenerse
/// sincronizada cuando se desliza el contenido.
class CarouselNavBar extends StatefulWidget {
  const CarouselNavBar({
    super.key,
    required this.controller,
    required this.items,
    required this.onSelect,
    this.onDragSelect,
  });

  final PageController controller;
  final List<NavItem> items;

  /// Se usa al pulsar una pestaña (con animación).
  final ValueChanged<int> onSelect;

  /// Se usa mientras se arrastra la barra (cambio inmediato).
  final ValueChanged<int>? onDragSelect;

  static const double height = 78;

  @override
  State<CarouselNavBar> createState() => _CarouselNavBarState();
}

class _CarouselNavBarState extends State<CarouselNavBar>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 240,
    damping: 23,
  );

  late final AnimationController _settle;
  double _slot = 0;
  double? _dragPage;
  double? _settlePage;
  int _dragIndex = 0;
  int _settleToken = 0;
  bool _traveling = false;
  double _travelFrom = 0;
  double _travelTo = 0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(_onSettleTick);
    widget.controller.addListener(_handleController);
  }

  @override
  void didUpdateWidget(covariant CarouselNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleController);
      widget.controller.addListener(_handleController);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleController);
    _settle.dispose();
    super.dispose();
  }

  List<double> _activeWeights(double activeIndex) {
    return [
      for (var i = 0; i < widget.items.length; i++)
        (1 - (i - activeIndex).abs()).clamp(0.0, 1.0),
    ];
  }

  void _handleController() {
    if (!_traveling) return;
    if ((_page() - _travelTo).abs() < 0.001) {
      setState(() => _traveling = false);
    }
  }

  double _page() {
    final controller = widget.controller;
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  double _maxPage() => (widget.items.length - 1).toDouble();

  double _visualPage() {
    if (_settlePage != null) {
      return _settlePage!.clamp(0.0, _maxPage());
    }
    if (_dragPage != null) {
      return _magnet(_dragPage!).clamp(0.0, _maxPage());
    }
    return _page();
  }

  /// Suaviza el crecimiento y la reducción de cada pestaña: evita que el
  /// cambio de tamaño se detenga de golpe al llegar a activa o inactiva.
  double _easeActive(double t) {
    final v = t.clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  /// Atrae la píldora hacia cada pestaña: se resiste a salir de una y luego
  /// se desliza con una curva suave a la siguiente.
  double _magnet(double page) {
    final base = page.floorToDouble();
    final fraction = page - base;
    final t = ((fraction - 0.18) / 0.64).clamp(0.0, 1.0);
    final eased = t * t * t * (t * (t * 6 - 15) + 10);
    return base + eased;
  }

  void _onSettleTick() {
    if (!mounted) return;
    setState(() {
      _settlePage = _settle.value.clamp(0.0, _maxPage());
    });
  }

  void _onTap(int index) {
    _settleToken++;
    _settle.stop();
    final current = _visualPage();

    setState(() {
      _dragPage = null;
      _settlePage = null;
      if ((current - index).abs() > 0.001) {
        _traveling = true;
        _travelFrom = current;
        _travelTo = index.toDouble();
      } else {
        _traveling = false;
      }
    });

    widget.onSelect(index);
  }

  void _onDragStart(DragStartDetails details) {
    _settleToken++;
    _settle.stop();
    _traveling = false;
    _dragPage = _settlePage ?? _dragPage ?? _page();
    _settlePage = null;
    _dragIndex = _magnet(_dragPage!).round().clamp(0, widget.items.length - 1);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_slot <= 0) return;

    final next = ((_dragPage ?? _page()) - details.delta.dx / _slot).clamp(
      0.0,
      _maxPage(),
    );
    setState(() => _dragPage = next);

    final index = _magnet(next).round().clamp(0, widget.items.length - 1);
    if (index != _dragIndex) {
      _dragIndex = index;
      (widget.onDragSelect ?? widget.onSelect)(index);
    }
  }

  void _onDragEnd([DragEndDetails? details]) {
    final current = _visualPage();
    final target = current.roundToDouble().clamp(0.0, _maxPage());
    _dragPage = null;
    _settlePage = current;
    _settle.value = current;

    final token = ++_settleToken;
    _settle
        .animateWith(SpringSimulation(_spring, current, target, 0))
        .whenCompleteOrCancel(() {
          if (!mounted || token != _settleToken) return;
          setState(() => _settlePage = null);
        });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final radius = BorderRadius.circular(CarouselNavBar.height / 2);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: CarouselNavBar.height,
            decoration: BoxDecoration(
              color: p.navGlass,
              borderRadius: radius,
              border: Border.all(color: p.border),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _slot = constraints.maxWidth / widget.items.length;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onHorizontalDragCancel: _onDragEnd,
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) {
                      final visualPage = _visualPage();
                      final travel = _traveling;
                      final progress = travel
                          ? ((_page() - _travelFrom) /
                                    (_travelTo - _travelFrom))
                                .clamp(0.0, 1.0)
                          : 0.0;

                      final actives = <double>[];
                      if (travel) {
                        final src = _activeWeights(_travelFrom);
                        final dst = _activeWeights(_travelTo);
                        for (var i = 0; i < widget.items.length; i++) {
                          actives.add(ui.lerpDouble(src[i], dst[i], progress)!);
                        }
                      } else {
                        actives.addAll(_activeWeights(visualPage));
                      }
                      for (var i = 0; i < actives.length; i++) {
                        actives[i] = _easeActive(actives[i]);
                      }

                      final total = actives.fold<double>(
                        0,
                        (a, active) => a + 1 + 0.38 * active,
                      );
                      final widths = [
                        for (final active in actives)
                          constraints.maxWidth * (1 + 0.38 * active) / total,
                      ];
                      final lefts = <double>[];
                      var x = 0.0;
                      for (final width in widths) {
                        lefts.add(x);
                        x += width;
                      }

                      double centerOf(int i) => lefts[i] + widths[i] / 2;

                      final double pillCenter;
                      // 0 cuando la píldora está en una pestaña, 1 a mitad de
                      // camino entre dos.
                      final double transit;
                      if (travel) {
                        final fromIndex = _travelFrom.round().clamp(
                          0,
                          widget.items.length - 1,
                        );
                        final toIndex = _travelTo.round().clamp(
                          0,
                          widget.items.length - 1,
                        );
                        pillCenter = ui.lerpDouble(
                          centerOf(fromIndex),
                          centerOf(toIndex),
                          progress,
                        )!;
                        transit = (1 - (2 * progress - 1).abs()).clamp(0.0, 1.0);
                      } else {
                        final from = visualPage.floor().clamp(
                          0,
                          widget.items.length - 1,
                        );
                        final to = visualPage.ceil().clamp(
                          0,
                          widget.items.length - 1,
                        );
                        final t = (visualPage - from).clamp(0.0, 1.0);
                        pillCenter = ui.lerpDouble(
                          centerOf(from),
                          centerOf(to),
                          t,
                        )!;
                        transit = (2 * (visualPage - visualPage.round()).abs())
                            .clamp(0.0, 1.0);
                      }

                      // Coseno: se encoge y crece con una curva suave, sin
                      // frenazos al entrar o salir de cada pestaña.
                      final emphasis = 0.5 + 0.5 * math.cos(math.pi * transit);
                      final pillWidth = ui.lerpDouble(34, 84, emphasis)!;
                      final pillHeight = ui.lerpDouble(34, 66, emphasis)!;

                      final lift = 1 - emphasis;

                      return Stack(
                        children: [
                          Positioned(
                            left: pillCenter - pillWidth / 2,
                            top:
                                (CarouselNavBar.height - pillHeight) / 2 -
                                6 * lift,
                            width: pillWidth,
                            height: pillHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(
                                  pillHeight / 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.accent.withValues(
                                      alpha: ui.lerpDouble(
                                        0.16,
                                        0.22,
                                        emphasis,
                                      )!,
                                    ),
                                    blurRadius: ui.lerpDouble(6, 14, emphasis)!,
                                    offset: Offset(
                                      0,
                                      ui.lerpDouble(2, 4, emphasis)!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Row(
                              children: [
                                for (var i = 0; i < widget.items.length; i++)
                                  SizedBox(
                                    width: widths[i],
                                    child: _NavButton(
                                      item: widget.items[i],
                                      distance: 1 - actives[i],
                                      onTap: () => _onTap(i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.distance,
    required this.onTap,
  });

  final NavItem item;

  /// 0 = activa, 1 = vecina, 2 o más = lejos.
  final double distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final active = (1 - distance).clamp(0.0, 1.0);
    final near = distance.clamp(0.0, 1.0);

    final opacity = ui.lerpDouble(0.62, 1.0, active)!;
    final foreground = Color.lerp(p.navIdle, p.onAccent, active)!;

    return Semantics(
      button: true,
      selected: near < 0.5,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: ui.lerpDouble(21, 25, active),
                  color: foreground,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: ui.lerpDouble(11, 13.5, active),
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
