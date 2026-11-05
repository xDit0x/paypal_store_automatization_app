import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/domain/repositories/assistant_repository/assistant_repository.dart';

/// Asistente de compras de mentira para la vista previa: pregunta la región,
/// la cantidad y enseña 3 distribuidores de leche de avena.
class PreviewAssistantRepository implements AssistantRepository {
  static const _options = [
    MarketOption(
      offerId: 'preview-1', distributorName: 'Horta Verda Distribucions', country: 'ES',
      city: 'Valencia', currency: 'EUR', website: null, rating: 4.6, leadDays: 2,
      productName: 'Bebida de avena barista 1 L', unit: 'L',
      notes: 'Marca propia, espuma estable para latte.', unitPrice: 1.45, minQty: 24,
      packSize: 12, orderQty: 48, extraUnits: 8, goodsEur: 69.6, shippingEur: 0,
      dutiesEur: 0, totalEur: 69.6, unitLandedEur: 1.45, outsideEu: false,
      tags: [MarketTag.cheapest], overBudget: false,
    ),
    MarketOption(
      offerId: 'preview-2', distributorName: 'Douro Bebidas Lda.', country: 'PT',
      city: 'Porto', currency: 'EUR', website: null, rating: 4.4, leadDays: 4,
      productName: 'Bebida de avena barista 1 L', unit: 'L', notes: null, unitPrice: 1.32,
      minQty: 36, packSize: 12, orderQty: 48, extraUnits: 8, goodsEur: 63.36,
      shippingEur: 14.4, dutiesEur: 0, totalEur: 77.76, unitLandedEur: 1.62,
      outsideEu: false, tags: [], overBudget: false,
    ),
    MarketOption(
      offerId: 'preview-3', distributorName: 'Castellana de Suministros', country: 'ES',
      city: 'Madrid', currency: 'EUR', website: null, rating: 4.8, leadDays: 1,
      productName: 'Bebida de avena barista 1 L', unit: 'L',
      notes: 'Entrega en 24 h en Madrid.', unitPrice: 1.52, minQty: 12, packSize: 6,
      orderQty: 42, extraUnits: 2, goodsEur: 63.84, shippingEur: 9.9, dutiesEur: 0,
      totalEur: 73.74, unitLandedEur: 1.76, outsideEu: false,
      tags: [MarketTag.fastest, MarketTag.bestRated], overBudget: false,
    ),
  ];

  @override
  Future<Either<AppError, AssistantReply>> send({
    required String storeId,
    required List<AssistantTurn> history,
    LastMarket? lastMarket,
    String? locale,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final users = history.where((t) => t.fromUser).length;
    if (users <= 1) {
      return const Right(AssistantReply(
        text: '¡Genial! ¿Qué producto quieres añadir al catálogo?',
        quickReplies: ['Leche de avena', 'Café en grano', 'Kombucha', 'Matcha'],
      ));
    }
    if (users == 2) {
      return const Right(AssistantReply(
        text: '¿Cuántas unidades necesitarías al mes, más o menos?',
        quickReplies: ['20', '40', '100', 'No lo sé'],
      ));
    }
    return const Right(AssistantReply(
      text: 'El más asequible es **Horta Verda**, de Valencia: **1,45 €** por litro puesto en tu tienda y con envío gratis. '
          'Castellana es algo más cara pero te lo trae en 24 h.',
      market: MarketResearch(
        searchId: null, query: 'leche de avena', region: 'europe', monthlyQuantity: 40,
        productName: 'Bebida de avena barista 1 L', compared: 7,
        countries: ['DE', 'ES', 'FR', 'NL', 'PT'], options: _options, webLeads: [], liveRates: true,
        demoDirectory: true,
      ),
    ));
  }

  // En la vista previa no hay servidor: se simula lo que "dijo" el dueño.
  static const _spoken = ['Quiero vender leche de avena', 'Europa', 'Unas cuarenta al mes'];

  @override
  Future<Either<AppError, VoiceReply>> voice({
    required String storeId,
    required List<AssistantTurn> history,
    required Uint8List wav,
    required String languageCode,
    LastMarket? lastMarket,
  }) async {
    final turn = history.where((t) => t.fromUser).length;
    final said = _spoken[turn.clamp(0, _spoken.length - 1).toInt()];
    final result = await send(
      storeId: storeId,
      history: [...history, AssistantTurn(fromUser: true, text: said)],
    );
    return result.map((reply) => VoiceReply(transcript: said, reply: reply));
  }

  @override
  Future<Uint8List?> speak(String text) async => null;

  @override
  Future<Either<AppError, AdoptResult>> adopt({
    required String storeId,
    required String offerId,
    String? searchId,
    int? quantity,
    required bool placeOrder,
    String? locale,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final option = _options.firstWhere((o) => o.offerId == offerId, orElse: () => _options.first);
    final qty = option.qtyFor(quantity);
    return Right(AdoptResult(
      supplierName: option.distributorName,
      productUid: 'mkt-preview-oat',
      productName: option.productName,
      unitPrice: option.unitLandedEur,
      currency: 'EUR',
      order: placeOrder
          ? AdoptedOrder(
              id: 'preview-order', qty: qty, total: option.unitLandedEur * qty,
              // Igual que en el servidor: el pedido queda pendiente de
              // aprobación y el stock sube al registrar la entrega.
              status: 'pending_approval', paid: false, reason: null, warnings: const [],
            )
          : null,
    ));
  }
}
