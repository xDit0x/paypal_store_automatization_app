import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:store_automatization_app/data/datasources/agent_repository/supabase_agent_datasource.dart';
import 'package:store_automatization_app/data/models/agent_run_model.dart';
import 'package:store_automatization_app/data/support/app_error_log.dart';
import 'package:store_automatization_app/domain/entities/agent_run.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';
import 'package:store_automatization_app/domain/repositories/agent_repository/agent_repository.dart';

class SupabaseAgentRepository implements AgentRepository {
  final SupabaseAgentDatasource _datasource;
  SupabaseAgentRepository(this._datasource);

  @override
  Future<Either<AppError, AgentRunResult>> run(String storeId) async {
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
        return const Left(AppError(AppErrorCode.sessionExpired));
      }
      return Left(
        logError(
          AppErrorCode.agentUnreachable,
          error,
          detail: serverMessage(error),
        ),
      );
    } catch (error) {
      return Left(logError(AppErrorCode.agentFailed, error));
    }
  }

  @override
  Future<Either<AppError, List<AgentRun>>> getRuns(String storeId) async {
    try {
      final rows = await _datasource.getRuns(storeId);
      return Right(rows.map(AgentRunModel.fromMap).toList());
    } catch (error) {
      return Left(logError(AppErrorCode.agentRunsLoadFailed, error));
    }
  }
}
