import 'package:store_automatization_app/core/configs/l10n/l10n.dart';
import 'package:store_automatization_app/domain/entities/app_error.dart';

/// Traduce los errores que llegan de datos y dominio.
///
/// El `switch` no tiene `default`: si se añade un [AppErrorCode] nuevo, esto
/// deja de compilar hasta que se le escriba su texto, así que no se puede
/// "olvidar" una traducción.
extension AppErrorL10n on AppLocalizations {
  /// Frase corta y traducida para el error.
  String describe(AppError error) => switch (error.code) {
    // Sesión y cuenta.
    AppErrorCode.authUserMissing => errorAuthUserMissing,
    AppErrorCode.authSignInFailed => errorAuthSignInFailed,
    AppErrorCode.authSignUpFailed => errorAuthSignUpFailed,
    AppErrorCode.authConfirmEmail => errorAuthConfirmEmail,
    AppErrorCode.authSignUpEmailRateLimited =>
      errorAuthSignUpEmailRateLimited,
    AppErrorCode.authSignOutFailed => errorAuthSignOutFailed,
    AppErrorCode.authResetEmailFailed => errorAuthResetEmailFailed,
    AppErrorCode.authInvalidCredentials => errorAuthInvalidCredentials,
    AppErrorCode.authEmailTaken => errorAuthEmailTaken,
    AppErrorCode.authWeakPassword => errorAuthWeakPassword,
    AppErrorCode.authEmailNotConfirmed => errorAuthEmailNotConfirmed,
    AppErrorCode.authResendConfirmFailed => errorAuthResendConfirmFailed,
    AppErrorCode.authTooManyAttempts => errorAuthTooManyAttempts,
    AppErrorCode.authValidationFailed => errorAuthValidationFailed,
    AppErrorCode.sessionExpired => errorSessionExpired,

    // Tienda.
    AppErrorCode.storeLoadFailed => errorStoreLoadFailed,
    AppErrorCode.storeUpdateFailed => errorStoreUpdateFailed,
    AppErrorCode.storeNotFound => errorStoreNotFound,
    AppErrorCode.storeNameEmpty => errorStoreNameEmpty,

    // Reglas de gasto.
    AppErrorCode.rulesNotFound => errorRulesNotFound,
    AppErrorCode.rulesLoadFailed => errorRulesLoadFailed,
    AppErrorCode.rulesSaveFailed => errorRulesSaveFailed,
    AppErrorCode.ruleMaxPerOrderInvalid => errorRuleMaxPerOrderInvalid,
    AppErrorCode.ruleMonthlyBelowMax => errorRuleMonthlyBelowMax,
    AppErrorCode.ruleApprovalAboveMax => errorRuleApprovalAboveMax,

    // Pedidos.
    AppErrorCode.ordersLoadFailed => errorOrdersLoadFailed,
    AppErrorCode.orderLoadFailed => errorOrderLoadFailed,
    AppErrorCode.orderCreateFailed => errorOrderCreateFailed,
    AppErrorCode.orderSpentFailed => errorOrderSpentFailed,
    AppErrorCode.orderApproveFailed => errorOrderApproveFailed,
    AppErrorCode.orderRejectFailed => errorOrderRejectFailed,
    AppErrorCode.orderMissing => errorOrderMissing,
    AppErrorCode.orderNotFound => errorOrderNotFound,
    AppErrorCode.orderEmpty => errorOrderEmpty,
    AppErrorCode.orderBlocked => errorOrderBlocked,
    AppErrorCode.orderItemInvalidQty => errorOrderItemInvalidQty(
      error.subject ?? '',
    ),
    AppErrorCode.orderProductMissing => errorOrderProductMissing(
      error.subject ?? '',
    ),
    AppErrorCode.orderProductInactive => errorOrderProductInactive(
      error.subject ?? '',
    ),
    AppErrorCode.invoiceLoadFailed => errorInvoiceLoadFailed,

    // Catálogo.
    AppErrorCode.suppliersLoadFailed => errorSuppliersLoadFailed,
    AppErrorCode.supplierLoadFailed => errorSupplierLoadFailed,
    AppErrorCode.catalogLoadFailed => errorCatalogLoadFailed,
    AppErrorCode.productSearchFailed => errorProductSearchFailed,
    AppErrorCode.productsLoadFailed => errorProductsLoadFailed,
    AppErrorCode.lowStockLoadFailed => errorLowStockLoadFailed,
    AppErrorCode.stockUpdateFailed => errorStockUpdateFailed,
    AppErrorCode.productMissing => errorProductMissing,
    AppErrorCode.productNotFound => errorProductNotFound(error.subject ?? ''),
    AppErrorCode.productUidMissing => errorProductUidMissing,
    AppErrorCode.stockNegative => errorStockNegative,

    // Agente.
    AppErrorCode.agentUnreachable => errorAgentUnreachable,
    AppErrorCode.agentFailed => errorAgentFailed,
    AppErrorCode.agentRunsLoadFailed => errorAgentRunsLoadFailed,
    AppErrorCode.agentStoreMissing => errorAgentStoreMissing,

    // Vista previa del diseño.
    AppErrorCode.previewNoSignOut => errorPreviewNoSignOut,
  };

  /// Texto para el cuerpo de un aviso: el motivo del servidor si lo hay, y
  /// si no la frase traducida del código.
  String describeDetail(AppError error) => error.detail ?? describe(error);
}
