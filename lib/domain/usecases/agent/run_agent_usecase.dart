import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';

class RunAgentUsecase {
  final AgentRepository repository;
  RunAgentUsecase({required this.repository});

  Future<Either<AppError, AgentRunResult>> call(String storeId) {
    if (storeId.isEmpty) {
      return Future.value(const Left(AppError(AppErrorCode.agentStoreMissing)));
    }
    return repository.run(storeId);
  }
}
