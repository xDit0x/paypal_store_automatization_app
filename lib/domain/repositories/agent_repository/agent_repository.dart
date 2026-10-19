import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/agent_run.dart';

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
  Future<Either<String, AgentRunResult>> run(String storeId);
  Future<Either<String, List<AgentRun>>> getRuns(String storeId);
}
