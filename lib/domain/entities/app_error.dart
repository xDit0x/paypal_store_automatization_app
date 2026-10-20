/// Fallo que se puede mostrar al usuario.
///
/// La capa de datos y el dominio no escriben frases: devuelven un
/// [AppErrorCode] y, solo si el servidor explicó el motivo, el texto en
/// [detail]. La traducción se resuelve en presentación con
/// `l10n.describe(error)`, así que cambiar de idioma no exige tocar ni los
/// repositorios ni los casos de uso.
class AppError {
  const AppError(this.code, {this.detail, this.subject});

  final AppErrorCode code;

  /// Explicación que manda el servidor (por ejemplo, por qué un pedido no
  /// supera las reglas). Ya viene redactada, así que se muestra tal cual.
  final String? detail;

  /// Dato al que se refiere el error: el UID de un producto, su nombre...
  final String? subject;

  @override
  bool operator ==(Object other) =>
      other is AppError &&
      other.code == code &&
      other.detail == detail &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(code, detail, subject);

  @override
  String toString() =>
      'AppError(${code.name}${subject == null ? '' : ', $subject'}'
      '${detail == null ? '' : ': $detail'})';
}

/// Todo lo que puede salir mal y llegar a la pantalla.
///
/// El `switch` de `AppErrorL10n.describe` es exhaustivo: si se añade un
/// código aquí y se olvida su texto, el proyecto no compila.
enum AppErrorCode {
  // Sesión y cuenta.
  authUserMissing,
  authSignInFailed,
  authSignUpFailed,
  authConfirmEmail,
  authSignOutFailed,
  authResetEmailFailed,
  authInvalidCredentials,
  authEmailTaken,
  authWeakPassword,
  authEmailNotConfirmed,
  authTooManyAttempts,
  authValidationFailed,
  sessionExpired,

  // Tienda.
  storeLoadFailed,
  storeUpdateFailed,
  storeNotFound,
  storeNameEmpty,

  // Reglas de gasto.
  rulesNotFound,
  rulesLoadFailed,
  rulesSaveFailed,
  ruleMaxPerOrderInvalid,
  ruleMonthlyBelowMax,
  ruleApprovalAboveMax,

  // Pedidos.
  ordersLoadFailed,
  orderLoadFailed,
  orderCreateFailed,
  orderSpentFailed,
  orderApproveFailed,
  orderRejectFailed,
  orderMissing,
  orderNotFound,
  orderEmpty,
  orderBlocked,
  orderItemInvalidQty,
  orderProductMissing,
  orderProductInactive,
  invoiceLoadFailed,

  // Catálogo.
  suppliersLoadFailed,
  supplierLoadFailed,
  catalogLoadFailed,
  productSearchFailed,
  productsLoadFailed,
  lowStockLoadFailed,
  stockUpdateFailed,
  productMissing,
  productNotFound,
  productUidMissing,
  stockNegative,

  // Agente.
  agentUnreachable,
  agentFailed,
  agentRunsLoadFailed,
  agentStoreMissing,

  // Vista previa del diseño.
  previewNoSignOut,
}
