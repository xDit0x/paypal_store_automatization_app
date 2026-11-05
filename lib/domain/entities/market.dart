/// Estudio de mercado del asistente: distribuidores comparados por coste real
/// (precio + envío + aranceles + cambio de moneda) puesto en la tienda.
library;

import 'dart:typed_data';

enum MarketTag { cheapest, fastest, bestRated }

class MarketOption {
  const MarketOption({
    required this.offerId,
    required this.distributorName,
    required this.country,
    required this.city,
    required this.currency,
    required this.website,
    required this.rating,
    required this.leadDays,
    required this.productName,
    required this.unit,
    required this.notes,
    required this.unitPrice,
    required this.minQty,
    required this.packSize,
    required this.orderQty,
    required this.extraUnits,
    required this.goodsEur,
    required this.shippingEur,
    required this.dutiesEur,
    required this.totalEur,
    required this.unitLandedEur,
    required this.outsideEu,
    required this.tags,
    required this.overBudget,
  });

  final String offerId;
  final String distributorName;

  /// Código ISO de 2 letras ("ES", "PT"...).
  final String country;
  final String? city;
  final String currency;
  final String? website;
  final double rating;
  final int leadDays;
  final String productName;
  final String unit;
  final String? notes;

  /// Precio por unidad en la moneda del distribuidor.
  final double unitPrice;
  final int minQty;
  final int packSize;
  final int orderQty;
  final int extraUnits;
  final double goodsEur;
  final double shippingEur;
  final double dutiesEur;
  final double totalEur;

  /// Coste real por unidad puesta en la tienda.
  final double unitLandedEur;
  final bool outsideEu;
  final List<MarketTag> tags;
  final bool overBudget;

  /// Unidades que habría que pedir para cubrir [wanted] (mínimo y cajas).
  int qtyFor(int? wanted) {
    final base = (wanted ?? 0) > minQty ? wanted! : minQty;
    final pack = packSize < 1 ? 1 : packSize;
    return (base / pack).ceil() * pack;
  }
}

class WebLead {
  const WebLead({required this.title, required this.url, required this.domain, required this.snippet});

  final String title;
  final String url;
  final String domain;
  final String snippet;
}

class MarketResearch {
  const MarketResearch({
    required this.searchId,
    required this.query,
    required this.region,
    required this.monthlyQuantity,
    required this.productName,
    required this.compared,
    required this.countries,
    required this.options,
    required this.webLeads,
    required this.liveRates,
  });

  final String? searchId;
  final String query;

  /// spain, europe o world.
  final String region;
  final int? monthlyQuantity;
  final String? productName;
  final int compared;
  final List<String> countries;
  final List<MarketOption> options;
  final List<WebLead> webLeads;

  /// false si se usaron tipos de cambio aproximados.
  final bool liveRates;
}

class AssistantReply {
  const AssistantReply({required this.text, this.quickReplies = const [], this.market, this.adopted});

  final String text;
  final List<String> quickReplies;
  final MarketResearch? market;

  /// El dueño eligió un distribuidor en la conversación ("me quedo con el primero").
  final AdoptResult? adopted;
}

/// Respuesta del modo conversación: lo que se entendió, la respuesta y su voz.
class VoiceReply {
  const VoiceReply({required this.transcript, required this.reply, this.audio});

  /// Lo que dijo el dueño (Whisper). Vacío si solo había silencio o ruido.
  final String transcript;
  final AssistantReply reply;

  /// MP3 de ElevenLabs. Null: se usa la voz del dispositivo.
  final Uint8List? audio;
}

class AdoptedOrder {
  const AdoptedOrder({
    required this.id,
    required this.qty,
    required this.total,
    required this.status,
    required this.paid,
    required this.reason,
    required this.warnings,
  });

  final String? id;
  final int qty;
  final double total;

  /// blocked, payment_failed, paid, completed, approved...
  final String status;
  final bool paid;
  final String? reason;
  final List<String> warnings;

  bool get blocked => status == 'blocked';
}

class AdoptResult {
  const AdoptResult({
    required this.supplierName,
    required this.productUid,
    required this.productName,
    required this.unitPrice,
    required this.currency,
    this.order,
  });

  final String supplierName;
  final String productUid;
  final String productName;
  final double unitPrice;
  final String currency;
  final AdoptedOrder? order;
}

/// Un turno de la conversación que se manda al servidor.
class AssistantTurn {
  const AssistantTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// Opciones que el dueño tiene delante, para elegir por voz.
class LastMarket {
  const LastMarket({required this.searchId, required this.monthlyQuantity, required this.options});

  final String? searchId;
  final int? monthlyQuantity;
  final List<MarketOption> options;

  Map<String, dynamic> toJson() => {
        'searchId': searchId,
        'monthlyQuantity': monthlyQuantity,
        'options': [
          for (final o in options)
            {
              'offerId': o.offerId,
              'distributorName': o.distributorName,
              'unitLandedEur': o.unitLandedEur,
              'orderQty': o.orderQty,
              'totalEur': o.totalEur,
            },
        ],
      };
}
