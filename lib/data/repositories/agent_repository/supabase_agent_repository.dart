import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:store_automatization_app/data/datasources/agent_repository/supabase_agent_datasource.dart';
import 'package:store_automatization_app/data/models/agent_run_model.dart';
import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';

class SupabaseAgentRepository implements AgentRepository {
  final SupabaseAgentDatasource _datasource;
  SupabaseAgentRepository(this._datasource);

  @override
  Future<Either<String, AgentRunResult>> run(String storeId) async {
    try {
      final data = await _datasource.run(storeId);
      return Right(
        AgentRunResult(
          orderId: (data['order_id'] ?? data['orderId']) as String?,
          decision: (data['decision'] as String?) ?? 'unknown',
          message: (data['message'] as String?) ?? '',
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return const Left('Sesión caducada. Vuelve a iniciar sesión.');
      }
      return Left('El agente no respondió: ${error.message ?? error}');
    } catch (error) {
      return Left('Error del agente: $error');
    }
  }

  @override
  Future<Either<String, List<AgentRun>>> getRuns(String storeId) async {
    try {
      final rows = await _datasource.getRuns(storeId);
      return Right(rows.map(AgentRunModel.fromMap).toList());
    } catch (error) {
      return Left('No se pudieron cargar las ejecuciones: $error');
    }
  }
}
