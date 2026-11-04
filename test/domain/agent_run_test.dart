import 'package:flutter_test/flutter_test.dart';

import 'package:store_automatization_app/data/models/agent_run_model.dart';

void main() {
  test('lee el motivo concreto de un pedido bloqueado', () {
    final run = AgentRunModel.fromMap({
      'id': 'r1',
      'store_id': 's1',
      'provider': 'groq',
      'model': 'llama-3.3-70b-versatile',
      'decision': 'blocked',
      'tool_calls': [
        {
          'ok': false,
          'blocked': true,
          'reason': 'supera el límite mensual (850.00 EUR de 800.00 EUR)',
        },
      ],
    });

    expect(
      run.blockedReason,
      'supera el límite mensual (850.00 EUR de 800.00 EUR)',
    );
  });

  test('una ejecución sin bloqueos no tiene motivo', () {
    final run = AgentRunModel.fromMap({
      'id': 'r2',
      'store_id': 's1',
      'provider': 'groq',
      'model': 'llama-3.3-70b-versatile',
      'decision': 'order_created',
      'tool_calls': [
        {'ok': true, 'order_id': 'o1'},
      ],
    });

    expect(run.blockedReason, isNull);
    expect(run.toolCalls, hasLength(1));
  });

  test('tolera ejecuciones antiguas sin tool_calls', () {
    final run = AgentRunModel.fromMap({
      'id': 'r3',
      'store_id': 's1',
      'provider': 'groq',
      'model': 'llama-3.3-70b-versatile',
      'decision': 'no_action',
    });

    expect(run.toolCalls, isEmpty);
    expect(run.blockedReason, isNull);
  });
}
