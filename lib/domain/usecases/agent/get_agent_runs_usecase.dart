import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';

class GetAgentRunsUsecase {
  final AgentRepository repository;
  GetAgentRunsUsecase({required this.repository});

  Future<Either<AppError, List<AgentRun>>> call(String storeId) =>
      repository.getRuns(storeId);
}
