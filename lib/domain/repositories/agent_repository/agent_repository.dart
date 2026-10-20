import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';

class AgentRunResult {
  final String? orderId;
  final String decision;
  final String message;

  const AgentRunResult({
    this.orderId,
    required this.decision,
    required this.message,
  });
}

abstract class AgentRepository {
  Future<Either<AppError, AgentRunResult>> run(String storeId);
  Future<Either<AppError, List<AgentRun>>> getRuns(String storeId);
}
