import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/core/network/dio_client.dart';
import 'package:store_automatization_app/core/ocr/ocr_service.dart';
import 'package:store_automatization_app/common/helpers/stocky_format.dart';
import 'package:store_automatization_app/domain/entities/order.dart';
import 'package:store_automatization_app/presentation/blocs/stocky/stocky_cubit.dart';

/// Confirma la entrega de un pedido autorizado y captura el pago
/// (total o parcial según lo recibido).
///
/// El albarán se lee con OCR local (Apple Vision en iOS, ML Kit en Android),
/// sin servicios de pago: la foto se procesa en el propio móvil y el texto
/// detectado se cruza con las líneas del pedido para proponer las cantidades
/// recibidas.
class DeliveryCheckPage extends StatefulWidget {
  const DeliveryCheckPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<DeliveryCheckPage> createState() => _DeliveryCheckPageState();
}

class _DeliveryCheckPageState extends State<DeliveryCheckPage> {
  final Map<String, int> _received = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _busy = false;
  bool _scanning = false;
  String? _error;
  String? _scanMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_received.isNotEmpty) return;
    final order = context.read<StockyCubit>().state.orderById(widget.orderId);
    if (order == null) return;
    for (final item in order.items) {
      _received[item.productUid] = item.qty;
      _controllers[item.productUid] = TextEditingController(
        text: '${item.qty}',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<StockyCubit>().state;
    final order = state.orderById(widget.orderId);

    if (order == null || order.status != OrderStatus.authorized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.deliveryScreenTitle)),
        body: Center(child: Text(l10n.deliveryNotAuthorized)),
      );
    }

    final receivedTotal = _receivedTotal(order);
    final orderedTotal = order.total;
    final missingTotal = math.max(0.0, orderedTotal - receivedTotal);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deliveryScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(order.id, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _TotalRow(
                    label: l10n.deliveryOrderedTotal,
                    value: l10n.eurosShort(orderedTotal, state.currency),
                  ),
                  _TotalRow(
                    label: l10n.deliveryReceivedTotal,
                    value: l10n.eurosShort(receivedTotal, state.currency),
                  ),
                  _TotalRow(
                    label: l10n.deliveryMissingTotal,
                    value: l10n.eurosShort(missingTotal, state.currency),
                    highlight: missingTotal > 0,
                  ),
                  const Divider(),
                  _TotalRow(
                    label: l10n.deliveryToCapture,
                    value: l10n.eurosShort(receivedTotal, state.currency),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.deliveryScanHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _scanning || _busy ? null : () => _scan(ImageSource.camera),
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _scanning ? l10n.deliveryScanning : l10n.deliveryScanButton,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _scanning || _busy ? null : () => _scan(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                tooltip: l10n.deliveryGalleryButton,
              ),
            ],
          ),
          if (_scanMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _scanMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          for (final item in order.items)
            _LineRow(
              name: item.name,
              expected: item.qty,
              controller: _controllers[item.productUid]!,
              onChanged: (value) {
                final qty = value.clamp(0, item.qty);
                setState(() => _received[item.productUid] = qty);
              },
            ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _busy || _scanning || receivedTotal <= 0 ? null : _onConfirm,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_busy ? l10n.deliveryConfirming : l10n.deliveryConfirm),
          ),
        ],
      ),
    );
  }

  double _receivedTotal(Order order) {
    var sum = 0.0;
    for (final item in order.items) {
      final qty = _received[item.productUid] ?? 0;
      sum += qty * item.unitPrice;
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  Future<void> _scan(ImageSource source) async {
    final l10n = context.l10n;
    final order = context.read<StockyCubit>().state.orderById(widget.orderId);
    if (order == null) return;

    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.deliveryScanError);
      return;
    }
    if (photo == null) return;

    setState(() {
      _scanning = true;
      _error = null;
      _scanMessage = null;
    });

    const recognizer = OcrService();
    try {
      final raw = await recognizer.recognizeText(photo.path);
      final matched = _applyOcr(raw, order);
      if (!mounted) return;
      setState(() {
        _scanMessage = l10n.deliveryScanSummary(matched, order.items.length);
      });
    } catch (_) {
      if (mounted) setState(() => _error = l10n.deliveryScanError);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Cruza las líneas del albarán con los productos del pedido y devuelve
  /// cuántas líneas se han reconocido.
  int _applyOcr(String raw, Order order) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    var matched = 0;

    for (final item in order.items) {
      final tokens = _normalize(item.name)
          .split(' ')
          .where((token) => token.length > 2)
          .toList();
      if (tokens.isEmpty) continue;

      int? qty;
      for (final line in lines) {
        final norm = _normalize(line);
        final hits = tokens.where(norm.contains).length;
        if (hits < math.max(1, (tokens.length / 2).ceil())) continue;

        final numbers = RegExp(r'\b\d{1,4}\b')
            .allMatches(line)
            .map((m) => int.parse(m.group(0)!))
            .where((n) => n > 0 && n <= item.qty * 3)
            .toList();
        if (numbers.isNotEmpty) {
          qty = numbers.first;
          break;
        }
      }

      if (qty == null) continue;
      final value = qty.clamp(0, item.qty);
      _received[item.productUid] = value;
      _controllers[item.productUid]?.text = '$value';
      matched++;
    }

    return matched;
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _onConfirm() async {
    final l10n = context.l10n;
    final cubit = context.read<StockyCubit>();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final dio = DioClient.create();
      await dio.post<Map<String, dynamic>>(
        '/orders/${widget.orderId}/capture',
        data: {
          'lines': [
            for (final entry in _received.entries)
              {'productUid': entry.key, 'qtyReceived': entry.value},
          ],
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      await cubit.load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deliverySuccess)));
      Navigator.of(context).maybePop();
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : l10n.deliveryError;
      if (mounted) setState(() => _error = message);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.deliveryError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? Colors.orange.shade800 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.name,
    required this.expected,
    required this.controller,
    required this.onChanged,
  });

  final String name;
  final int expected;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final received = int.tryParse(controller.text) ?? 0;
    final missing = expected - received;

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
                  Text(l10n.deliveryExpected(expected)),
                  if (missing > 0)
                    Text(
                      l10n.deliveryMissing(missing),
                      style: const TextStyle(color: Colors.orange),
                    ),
                  if (missing < 0)
                    Text(
                      l10n.deliveryExtra(-missing),
                      style: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 84,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                controller: controller,
                onChanged: (value) {
                  final parsed = int.tryParse(value) ?? 0;
                  onChanged(parsed);
                },
                decoration: InputDecoration(
                  labelText: l10n.deliveryReceived,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
