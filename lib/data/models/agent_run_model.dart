import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/domain/entities/agent_run.dart';

class AgentRunModel {
  const AgentRunModel._();

  static AgentRun fromMap(Map<String, dynamic> map) {
    return AgentRun(
      id: map['id'] as String,
      storeId: map['store_id'] as String,
      orderId: map['order_id'] as String?,
      provider: map['provider'] as String? ?? 'groq',
      model: map['model'] as String? ?? '',
      decision: map['decision'] as String?,
      confidence: map['confidence'] == null ? null : asDouble(map['confidence']),
      createdAt: asDateTime(map['created_at']),
    );
  }
}
