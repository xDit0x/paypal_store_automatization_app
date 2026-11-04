import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/entities/market.dart';

/// Conversación con el asistente de compras y alta de distribuidores.
abstract class AssistantRepository {
  Future<Either<AppError, AssistantReply>> send({
    required String storeId,
    required List<AssistantTurn> history,
    /// Idioma de la app ('es' o 'en') para que el asistente conteste en él.
    String? locale,
  });

  Future<Either<AppError, AdoptResult>> adopt({
    required String storeId,
    required String offerId,
    String? searchId,
    int? quantity,
    required bool placeOrder,
    /// Idioma de la app ('es' o 'en').
    String? locale,
  });
}
