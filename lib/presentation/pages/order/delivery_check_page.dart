import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';

/// Confirma la entrega de un pedido autorizado y captura el pago
/// (total o parcial según lo recibido).
class DeliveryCheckPage extends StatefulWidget {
  const DeliveryCheckPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryCheckPage> createState() => _DeliveryCheckPageState();
}

class _DeliveryCheckPageState extends State<DeliveryCheckPage> {
  final Map<String, int> _received = {};
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_received.isEmpty) {
      // Usamos context aquí, ya es seguro
      final cubit = context.read<StockyCubit>();
      final order = cubit.state.orderById(widget.orderId);
      if (order != null) {
        for (final item in order.items) {
          _received[item.productUid] = item.qty;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StockyCubit>().state;
    final order = state.orderById(widget.orderId);

    if (order == null || order.status != OrderStatus.authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entrega')),
        body: const Center(child: Text('Pedido no autorizado para entrega.')),
      );
    }

    final lines = order.items.map((item) {
      final qty = _received[item.productUid] ?? item.qty;
      final expected = item.qty;
      return _LineRow(
        name: item.name,
        expected: expected,
        qty: qty,
        onChanged: (v) => setState(() => _received[item.productUid] = v),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Entrega · ${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pedido ${order.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text('Estado: ${order.status.value}'),
          const SizedBox(height: 12),
          Text(
            'Indica cuánto ha llegado de cada producto:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...lines,
          const SizedBox(height: 16),
          if (_error != null)
            Text('Error: $_error', style: TextStyle(color: Colors.red)),
          ElevatedButton.icon(
            onPressed: _busy ? null : _onConfirm,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _busy ? 'Confirmando...' : 'Confirmar entrega y cobrar',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _busy = true);
    try {
      final dio = Dio();
      final body = {
        'lines': _received.entries
            .map((e) => {'productUid': e.key, 'qtyReceived': e.value})
            .toList(),
      };

      // El endpoint real está detrás del backend; usamos el host de desarrollo.
      const baseUrl = 'http://localhost:3000';
      await dio.post('$baseUrl/orders/${widget.orderId}/capture', data: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega confirmada. Pago capturado.')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.name,
    required this.expected,
    required this.qty,
    required this.onChanged,
  });

  final String name;
  final int expected;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                  Text('Esperado: $expected  ·  Recibido: $qty'),
                  if ((qty - expected) < 0)
                    Text(
                      'Faltan ${(expected - qty)}',
                      style: TextStyle(color: Colors.orange),
                    ),
                  if ((qty - expected) > 0)
                    Text(
                      'Sobran ${qty - expected}',
                      style: TextStyle(color: Colors.green),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                controller: TextEditingController(text: qty.toString()),
                onChanged: (v) {
                  final n = int.tryParse(v) ?? expected;
                  onChanged(n.clamp(0, expected * 2));
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
