import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:store_automatization_app/core/configs/theme/restock_palette.dart';
import 'package:store_automatization_app/domain/entities/product.dart';
import 'package:store_automatization_app/presentation/blocs/restock/restock_state.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_common.dart';
import 'package:store_automatization_app/presentation/widgets/restock/restock_ui.dart';

enum _Filter { all, low, transit }

/// Pestaña Stock: todos los productos de los catálogos, con búsqueda por
/// nombre o UID y filtro.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  _Filter _filter = _Filter.all;
  String _query = '';

  List<Product> _visible(RestockState state) {
    final q = _query.trim().toLowerCase();
    return state.products.where((p) {
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q) || p.uid.toLowerCase().contains(q);
      final matchesFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.low => p.isLowStock,
        _Filter.transit => state.isInTransit(p),
      };
      return p.active && matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return RTabPage(
      builder: (context, state) {
        final p = context.rp;
        final t = context.rt;
        final products = _visible(state);
        final segmentStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink);

        return [
          const RLargeTitle('Stock'),
          const SizedBox(height: 16),
          CupertinoSearchTextField(
            placeholder: 'Buscar por nombre o UID',
            backgroundColor: p.fill,
            style: TextStyle(color: p.ink),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<_Filter>(
              groupValue: _filter,
              backgroundColor: p.fill,
              thumbColor: p.surface,
              children: {
                _Filter.all: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('Todos', style: segmentStyle),
                ),
                _Filter.low: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('Bajo mínimo', style: segmentStyle),
                ),
                _Filter.transit: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('En camino', style: segmentStyle),
                ),
              },
              onValueChanged: (value) => setState(() => _filter = value ?? _Filter.all),
            ),
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            REmptyState(
              icon: CupertinoIcons.cube_box,
              title: state.products.isEmpty ? 'Aún no hay productos' : 'Nada con ese filtro',
              message: state.products.isEmpty ? 'Los catálogos de tus proveedores aparecerán aquí.' : null,
            )
          else
            RInsetGroup(children: [for (final product in products) _ProductRow(product: product, state: state)]),
          if (products.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(child: Text('${products.length} productos', style: t.caption)),
          ],
        ];
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.state});

  final Product product;
  final RestockState state;

  @override
  Widget build(BuildContext context) {
    final p = context.rp;
    final t = context.rt;
    final inTransit = state.isInTransit(product);

    final (String label, Color text, Color bar, bool strong) = inTransit
        ? ('En camino', p.transit, p.transit, true)
        : product.stock <= 0
            ? ('Agotado', p.warning, p.warningBar, true)
            : product.isLowStock
                ? ('Bajo mínimo', p.warning, p.warningBar, true)
                : ('Correcto', p.inkSecondary, p.neutralBar, false);

    // La barra llega al 100 % con el doble del mínimo.
    final reference = product.lowStockThreshold <= 0 ? 1 : product.lowStockThreshold * 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(product.name, style: t.headline)),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: strong ? FontWeight.w600 : FontWeight.w400, color: text),
              ),
            ],
          ),
          const SizedBox(height: 7),
          RLevelBar(value: product.stock / reference, color: bar),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${product.stock} ${product.unit} · mín. ${product.lowStockThreshold}',
                  style: t.footnote,
                ),
              ),
              Flexible(
                child: Text(
                  state.supplierName(product.supplierId),
                  style: t.footnote,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(product.uid, style: t.caption.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
