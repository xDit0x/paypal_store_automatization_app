import 'package:store_automatization_app/domain/entities/market.dart';

/// Lectura de las respuestas JSON de /assistant/message y /assistant/adopt.
class MarketModel {
  const MarketModel._();

  static double _d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static int _i(Object? v) => v is num ? v.round() : int.tryParse('$v') ?? 0;
  static String? _s(Object? v) => v is String && v.isNotEmpty ? v : null;
  static Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
  static List<Object?> _l(Object? v) => v is List ? v : const [];

  static MarketTag? _tag(Object? v) => switch (v) {
        'cheapest' => MarketTag.cheapest,
        'fastest' => MarketTag.fastest,
        'best_rated' => MarketTag.bestRated,
        _ => null,
      };

  static MarketOption option(Map<String, dynamic> m) => MarketOption(
        offerId: '${m['offerId']}',
        distributorName: '${m['distributorName'] ?? ''}',
        country: '${m['country'] ?? ''}',
        city: _s(m['city']),
        currency: '${m['currency'] ?? 'EUR'}',
        website: _s(m['website']),
        rating: _d(m['rating']),
        leadDays: _i(m['leadDays']),
        productName: '${m['productName'] ?? ''}',
        unit: '${m['unit'] ?? ''}',
        notes: _s(m['notes']),
        unitPrice: _d(m['unitPrice']),
        minQty: _i(m['minQty']),
        packSize: _i(m['packSize']),
        orderQty: _i(m['orderQty']),
        extraUnits: _i(m['extraUnits']),
        goodsEur: _d(m['goodsEur']),
        shippingEur: _d(m['shippingEur']),
        dutiesEur: _d(m['dutiesEur']),
        totalEur: _d(m['totalEur']),
        unitLandedEur: _d(m['unitLandedEur']),
        outsideEu: m['outsideEu'] == true,
        tags: _l(m['tags']).map(_tag).whereType<MarketTag>().toList(),
        overBudget: m['overBudget'] == true,
      );

  static MarketResearch research(Map<String, dynamic> m) => MarketResearch(
        searchId: _s(m['searchId']),
        query: '${m['query'] ?? ''}',
        region: '${m['region'] ?? 'world'}',
        monthlyQuantity: m['monthlyQuantity'] == null ? null : _i(m['monthlyQuantity']),
        productName: _s(m['productName']),
        compared: _i(m['compared']),
        countries: _l(m['countries']).map((c) => '$c').toList(),
        options: _l(m['offers']).map((o) => option(_m(o))).toList(),
        webLeads: _l(m['webResults'])
            .map(_m)
            .where((w) => _s(w['url']) != null)
            .map((w) => WebLead(
                  title: '${w['title'] ?? ''}',
                  url: '${w['url']}',
                  domain: '${w['domain'] ?? ''}',
                  snippet: '${w['snippet'] ?? ''}',
                ))
            .toList(),
        liveRates: m['fxSource'] != 'fallback',
        demoDirectory: m['demoDirectory'] == true,
      );

  static AssistantReply reply(Map<String, dynamic> m) => AssistantReply(
        text: '${m['reply'] ?? ''}',
        quickReplies: _l(m['quick_replies']).map((q) => '$q').where((q) => q.isNotEmpty).toList(),
        market: m['market'] is Map ? research(_m(m['market'])) : null,
      );

  static AdoptResult adopt(Map<String, dynamic> m) {
    final order = m['order'] is Map ? _m(m['order']) : null;
    return AdoptResult(
      supplierName: '${m['supplierName'] ?? ''}',
      productUid: '${m['productUid'] ?? ''}',
      productName: '${m['productName'] ?? ''}',
      unitPrice: _d(m['unitPrice']),
      currency: '${m['currency'] ?? 'EUR'}',
      order: order == null
          ? null
          : AdoptedOrder(
              id: _s(order['id']),
              qty: _i(order['qty']),
              total: _d(order['total']),
              status: '${order['status'] ?? ''}',
              paid: order['paid'] == true,
              reason: _s(order['reason']),
              warnings: _l(order['warnings']).map((w) => '$w').toList(),
            ),
    );
  }
}
