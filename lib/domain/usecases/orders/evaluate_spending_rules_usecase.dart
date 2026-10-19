import 'package:store_automatization_app/domain/entities/spending_rules.dart';

class EvaluateSpendingRulesUsecase {
  const EvaluateSpendingRulesUsecase();

  SpendingDecision call({
    required SpendingRules rules,
    required double orderTotal,
    required double spentThisMonth,
    required String supplierId,
  }) {
    return rules.evaluate(
      orderTotal: orderTotal,
      spentThisMonth: spentThisMonth,
      supplierId: supplierId,
    );
  }
}
