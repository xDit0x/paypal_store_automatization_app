import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/data/models/market_model.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';
import 'package:store_automatization_app/domain/repositories/assistant_repository/assistant_repository.dart';
import 'package:store_automatization_app/presentation/blocs/assistant/assistant_cubit.dart';

const _offerJson = {
  'offerId': 'o1', 'distributorName': 'Horta Verda', 'country': 'ES', 'city': 'Valencia',
  'currency': 'EUR', 'website': null, 'rating': 4.6, 'leadDays': 2,
  'productName': 'Avena 1 L', 'unit': 'L', 'notes': null, 'unitPrice': 1.45, 'minQty': 24,
  'packSize': 12, 'orderQty': 48, 'extraUnits': 8, 'goodsEur': 69.6, 'shippingEur': 0,
  'dutiesEur': 0, 'totalEur': 69.6, 'unitLandedEur': 1.45, 'outsideEu': false,
  'tags': ['cheapest', 'best_rated', 'raro'], 'overBudget': false,
};

class _FakeRepo implements AssistantRepository {
  final sent = <List<AssistantTurn>>[];
  bool fail = false;

  @override
  Future<Either<AppError, AssistantReply>> send({
    required String storeId,
    required List<AssistantTurn> history,
    LastMarket? lastMarket,
    String? locale,
  }) async {
    sent.add(history);
    if (fail) return const Left(AppError(AppErrorCode.agentUnreachable));
    return const Right(AssistantReply(text: '¿Dónde busco?', quickReplies: ['España', 'Europa']));
  }

  @override
  Future<Either<AppError, VoiceReply>> voice({
    required String storeId,
    required List<AssistantTurn> history,
    required Uint8List wav,
    required String languageCode,
    LastMarket? lastMarket,
  }) async =>
      const Right(VoiceReply(
        transcript: 'el primero',
        reply: AssistantReply(text: '¿Confirmo el pedido?', quickReplies: ['Sí, hazlo', 'No']),
      ));

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
  }) async =>
      throw UnimplementedError();
}

void main() {
  test('lee la respuesta del servidor con el estudio de mercado', () {
    final reply = MarketModel.reply({
      'reply': 'Hola',
      'quick_replies': ['a', ''],
      'market': {
        'searchId': 's1', 'query': 'avena', 'region': 'europe', 'monthlyQuantity': 40,
        'productName': 'Avena 1 L', 'compared': 7, 'countries': ['ES', 'PT'],
        'offers': [_offerJson], 'webResults': [{'title': 'x', 'url': 'https://x.com', 'domain': 'x.com'}],
        'fxSource': 'fallback',
      },
    });
    expect(reply.quickReplies, ['a']);
    final market = reply.market!;
    expect(market.monthlyQuantity, 40);
    expect(market.liveRates, isFalse);
    expect(market.webLeads.single.domain, 'x.com');
    final option = market.options.single;
    expect(option.tags, [MarketTag.cheapest, MarketTag.bestRated]);
    expect(option.unitLandedEur, 1.45);
  });

  test('cantidad a pedir: mínimo y cajas completas', () {
    final option = MarketModel.option(Map<String, dynamic>.from(_offerJson));
    expect(option.qtyFor(null), 24);
    expect(option.qtyFor(10), 24);
    expect(option.qtyFor(40), 48);
  });

  test('lee el resultado de añadir un distribuidor', () {
    final result = MarketModel.adopt({
      'supplierName': 'Horta', 'productUid': 'mkt-x', 'productName': 'Avena', 'unitPrice': 1.45,
      'currency': 'EUR',
      'order': {'id': null, 'qty': 48, 'total': 69.6, 'status': 'blocked', 'paid': false, 'reason': 'Tope'},
    });
    expect(result.order!.blocked, isTrue);
    expect(result.order!.reason, 'Tope');
  });

  test('el cubit guarda la conversación y manda el historial', () async {
    final repo = _FakeRepo();
    final cubit = AssistantCubit(repository: repo);

    final reply = await cubit.send('store', 'Quiero vender kombucha', viaVoice: true);
    expect(reply?.quickReplies, ['España', 'Europa']);
    expect(reply?.viaVoice, isTrue);
    expect(cubit.state.entries.length, 2);
    expect(repo.sent.single.single.text, 'Quiero vender kombucha');

    repo.fail = true;
    expect(await cubit.send('store', 'Europa'), isNull);
    expect(cubit.state.entries.last.error, isNotNull);
    expect(cubit.state.sending, isFalse);

    // Los errores no se mandan como historial.
    repo.fail = false;
    await cubit.send('store', 'Europa');
    expect(repo.sent.last.length, 4);
    await cubit.close();
  });

  test('modo conversación: añade lo que se entendió y la respuesta', () async {
    final cubit = AssistantCubit(repository: _FakeRepo());
    final result = await cubit.sendVoice('store', Uint8List(4000), 'es');
    expect(result.isRight(), isTrue);
    expect(cubit.state.entries.map((e) => e.text), ['el primero', '¿Confirmo el pedido?']);
    expect(cubit.state.entries.first.fromUser, isTrue);
    expect(cubit.state.sending, isFalse);
    await cubit.close();
  });
}
