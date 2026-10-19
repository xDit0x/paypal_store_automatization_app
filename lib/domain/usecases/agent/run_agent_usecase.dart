import 'package:dartz/dartz.dart';

import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';

class RunAgentUsecase {
  final AgentRepository repository;
  RunAgentUsecase({required this.repository});

  Future<Either<String, AgentRunResult>> call(String storeId) {
    if (storeId.isEmpty) {
      return Future.value(const Left('Falta la tienda.'));
    }
    return repository.run(storeId);
  }
}
