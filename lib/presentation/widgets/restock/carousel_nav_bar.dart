import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';

class NavItem {
  const NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Barra inferior en carrusel: la pestaña activa queda grande y en el centro
/// y las demás más pequeñas a los lados. Se cambia pulsando o deslizando.
///
/// Va enganchada al [PageController] de las pantallas, así que también se
/// mueve cuando el usuario desliza el contenido.
class CarouselNavBar extends StatelessWidget {
  const CarouselNavBar({
    super.key,
    required this.controller,
    required this.items,
    required this.onSelect,
  });

  final PageController controller;
  final List<NavItem> items;
  final ValueChanged<int> onSelect;

  static const double itemWidth = 78;
  static const double height = 72;

  double _page() {
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? controller.initialPage.toDouble();
    }
    return controller.initialPage.toDouble();
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final current = _page().round();
    if (velocity < -150 && current < items.length - 1) onSelect(current + 1);
    if (velocity > 150 && current > 0) onSelect(current - 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final radius = BorderRadius.circular(height / 2);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: p.navGlass,
              borderRadius: radius,
              border: Border.all(color: p.border),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: _onDragEnd,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final center = constraints.maxWidth / 2;
                  return ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0, 0.16, 0.84, 1],
                    ).createShader(rect),
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final page = _page();
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Positioned(
                                left: center - itemWidth / 2 + (i - page) * itemWidth,
                                top: 0,
                                bottom: 0,
                                width: itemWidth,
                                child: _NavButton(
                                  item: items[i],
                                  distance: (i - page).abs(),
                                  onTap: () => onSelect(i),
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
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.distance, required this.onTap});

  final NavItem item;

  /// 0 = activa, 1 = vecina, 2 o más = lejos.
  final double distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final near = distance.clamp(0.0, 1.0);
    final far = (distance - 1).clamp(0.0, 1.0);

    final scale = ui.lerpDouble(ui.lerpDouble(1.08, 0.86, near), 0.72, far)!;
    final opacity = ui.lerpDouble(ui.lerpDouble(1.0, 0.8, near), 0.45, far)!;
    final active = 1 - near;
    final background = Color.lerp(p.accent.withValues(alpha: 0), p.accent, active)!;
    final foreground = Color.lerp(p.navIdle, p.onAccent, active)!;

    return Semantics(
      button: true,
      selected: distance < 0.5,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 56,
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 24, color: foreground),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
