import 'package:store_automatization_app/data/models/model_utils.dart';
import 'package:store_automatization_app/domain/entities/spending_rules.dart';

class SpendingRulesModel {
  const SpendingRulesModel._();

  static SpendingRules fromMap(Map<String, dynamic> map) {
    return SpendingRules(
      maxPerOrder: asDouble(map['max_per_order'], fallback: 200),
      monthlyLimit: asDouble(map['monthly_limit'], fallback: 800),
      requireApprovalAbove:
          asDouble(map['require_approval_above'], fallback: 50),
      allowedSupplierIds: asStringList(map['allowed_supplier_ids']),
    );
  }

  static Map<String, dynamic> toMap(SpendingRules rules) {
    return {
      'max_per_order': rules.maxPerOrder,
      'monthly_limit': rules.monthlyLimit,
      'require_approval_above': rules.requireApprovalAbove,
      'allowed_supplier_ids': rules.allowedSupplierIds,
    };
  }
}
