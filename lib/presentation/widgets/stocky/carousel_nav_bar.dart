import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:store_automatization_app/core/configs/theme/stocky_palette.dart';

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
    with TickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 240,
    damping: 23,
  );

  /// Duración de cada salto en el efecto cascada de la píldora. Cada salto
  /// tiene que dar tiempo a verse: si va muy rápido parece un teletransporte.
  static const _hopStep = Duration(milliseconds: 165);

  late final AnimationController _settle;

  /// Cascada: la píldora recorre una a una las pestañas intermedias hasta
  /// llegar a la elegida, mientras el contenido ya está en su destino.
  late final AnimationController _hop = AnimationController(vsync: this)
    ..addListener(_onHopTick)
    ..addStatusListener(_onHopStatus);

  double _hopFrom = 0;
  double _hopTo = 0;
  int _hopSteps = 0;
  bool _hopping = false;

  double _slot = 0;
  double _lastPage = 0;
  double? _dragPage;
  double? _settlePage;
  int _dragIndex = 0;
  int _settleToken = 0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController.unbounded(vsync: this)
      ..addListener(_onSettleTick);
    _lastPage = widget.controller.initialPage.toDouble();
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
    _hop.dispose();
    super.dispose();
  }

  List<double> _activeWeights(double activeIndex) {
    return [
      for (var i = 0; i < widget.items.length; i++)
        (1 - (i - activeIndex).abs()).clamp(0.0, 1.0),
    ];
  }

  void _handleController() {
    final controller = widget.controller;
    if (controller.hasClients && controller.position.haveDimensions) {
      final page = controller.page;
      if (page != null) _lastPage = page;
    }
  }

  /// Página actual del contenido. Si el visor pierde las dimensiones a
  /// mitad de un rebuild (por ejemplo, al cambiar el tema) se devuelve la
  /// última página conocida para que la píldora no salte a "Inicio".
  double _page() {
    final controller = widget.controller;
    if (controller.hasClients && controller.position.haveDimensions) {
      final page = controller.page;
      if (page != null) return page;
    }
    return _lastPage;
  }

  double _maxPage() => (widget.items.length - 1).toDouble();

  /// Arranca la cascada: la píldora va pasando una a una por las pestañas
  /// intermedias hasta llegar a [to]. El contenido, en cambio, ya salta
  /// directo (lo hace el shell con `jumpToPage`).
  void _startHop(double from, double to) {
    _hopFrom = from;
    _hopTo = to;
    _hopSteps = (to - from).abs().round();
    if (_hopSteps <= 0) {
      _hopping = false;
      return;
    }
    _hopping = true;
    _hop.duration = _hopStep * _hopSteps;
    _hop.forward(from: 0);
  }

  void _onHopTick() {
    // La píldora se redibuja desde el `AnimatedBuilder`, que ya escucha la
    // cascada: aquí no hace falta reconstruir toda la barra.
  }

  void _onHopStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      setState(() => _hopping = false);
    }
  }

  /// Posición de la píldora durante la cascada: recorre los enteros
  /// intermedios con un salto suave entre cada uno.
  double _hopPage() {
    final dist = _hopTo - _hopFrom;
    if (_hopSteps <= 0 || dist.abs() <= 0.0001) return _hopTo;
    // Longitud real de cada tramo: si la cascada se interrumpió a media
    // camino, el último tramo es más corto y la píldora cae exacta en la
    // pestaña de destino.
    final perStep = dist.abs() / _hopSteps;
    final t = _hop.value * _hopSteps;
    final segment = t.floorToDouble();
    final within = t - segment;
    // Dentro de cada tramo la píldora arranca despacio, acelera y vuelve a
    // frenar justo al posarse en la pestaña: se ve pasar una a una.
    final eased = Curves.easeInOutCubic.transform(within);
    final dir = dist.sign;
    return (_hopFrom + dir * (segment + eased) * perStep).clamp(
      0.0,
      _maxPage(),
    );
  }

  /// Efecto burbuja: cómo de hinchada está la píldora durante la cascada.
  ///
  /// 1 = tamaño real; 0 = burbuja pequeña (34 px). Se deshincha al salir de
  /// la pestaña, viaja pequeña por todo el camino y se hincha al llegar al
  /// destino con un pequeño rebote.
  ///
  /// El estirón de salida y el de llegada duran medio salto cada uno: así la
  /// píldora va pequeña durante todo el trayecto (no da un bote por cada
  /// pestaña intermedia) y aun así el cambio se ve incluso al saltar a la
  /// pestaña de al lado.
  double _bubbleEmphasis() {
    final steps = _hopSteps;
    if (steps <= 0) return 1;

    final edge = 0.5 / steps;
    final t = _hop.value.clamp(0.0, 1.0);

    // Al salir: se deshincha hasta quedarse en burbuja.
    if (t < edge) {
      return 1 - Curves.easeInOutSine.transform((t / edge).clamp(0.0, 1.0));
    }
    // Al llegar: se hincha de nuevo, con un rebote suave.
    if (t > 1 - edge) {
      return Curves.easeOutBack
          .transform(((t - (1 - edge)) / edge).clamp(0.0, 1.0))
          .clamp(0.0, 1.08);
    }
    // En el camino: burbuja pequeña.
    return 0.0;
  }

  double _visualPage() {
    if (_hopping) {
      return _hopPage();
    }
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
    });

    // Efecto cascada: la píldora pasa una a una por las pestañas
    // intermedias hasta llegar a la elegida.
    _startHop(current, index.toDouble());

    widget.onSelect(index);
  }

  void _onDragStart(DragStartDetails details) {
    _settleToken++;
    _settle.stop();
    _hopping = false;
    _hop.stop();
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
                    // Escucha también la cascada: así la píldora se anima
                    // sin tener que reconstruir la barra (con su blur).
                    animation: Listenable.merge([widget.controller, _hop]),
                    builder: (context, _) {
                      final visualPage = _visualPage();

                      // Las pestañas se resaltan según dónde esté la píldora:
                      // en la cascada se va encendiendo una a una al pasar.
                      final actives = _activeWeights(visualPage);
                      for (var i = 0; i < actives.length; i++) {
                        actives[i] = _easeActive(actives[i]);
                      }

                      final total = actives.fold<double>(
                        0,
                        (a, active) => a + 1 + 0.46 * active,
                      );
                      final widths = [
                        for (final active in actives)
                          constraints.maxWidth * (1 + 0.46 * active) / total,
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

                      // Burbuja: la píldora se deshincha al salir de una
                      // pestaña, viaja pequeña (34 px) y se hincha otra vez
                      // al llegar, con un rebote final.
                      final double emphasis;
                      // Cuánto se eleva la píldora del centro de la barra.
                      final double lift;
                      // Cuánto se aclara el azul mientras está en camino.
                      final double travelMix;
                      if (_hopping) {
                        emphasis = _bubbleEmphasis();
                        lift = 1 - emphasis;
                        // El rebote final deja `emphasis` por encima de 1:
                        // se recorta para que el color no se pase de azul.
                        travelMix = (1 - emphasis).clamp(0.0, 1.0) * 0.6;
                      } else {
                        // Coseno: se encoge y crece con una curva suave, sin
                        // frenazos al entrar o salir de cada pestaña.
                        emphasis = 0.5 + 0.5 * math.cos(math.pi * transit);
                        lift = 1 - emphasis;
                        travelMix = transit.clamp(0.0, 1.0) * 0.75;
                      }
                      final pillWidth = ui.lerpDouble(34, 84, emphasis)!;
                      final pillHeight = ui.lerpDouble(34, 66, emphasis)!;

                      final pillColor = Color.lerp(
                        p.accent,
                        p.accentLight,
                        travelMix,
                      )!;

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
                                color: pillColor,
                                borderRadius: BorderRadius.circular(
                                  pillHeight / 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: pillColor.withValues(
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
                  size: ui.lerpDouble(20, 27, active),
                  color: foreground,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: ui.lerpDouble(10.5, 14, active),
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
