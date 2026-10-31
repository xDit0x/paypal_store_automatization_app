// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Restock';

  @override
  String get appTagline => 'Pedidos automáticos con IA + PayPal';

  @override
  String get configErrorTitle => 'Configuración incompleta';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionOk => 'Vale';

  @override
  String get actionSend => 'Enviar';

  @override
  String get actionSignOut => 'Cerrar sesión';

  @override
  String get actionCreateAccount => 'Crear una cuenta';

  @override
  String get actionSignIn => 'Iniciar sesión';

  @override
  String get actionCreateMyStore => 'Crear mi tienda';

  @override
  String get actionAlreadyHaveAccount => 'Ya tengo cuenta';

  @override
  String get actionForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get actionApproveAndPay => 'Aprobar y pagar con PayPal';

  @override
  String get actionReject => 'Rechazar';

  @override
  String get actionConfirmDelivery => 'Confirmar entrega';

  @override
  String get actionReviewStockNow => 'Revisar stock ahora';

  @override
  String get actionRemoveOneUnit => 'Quitar una unidad';

  @override
  String get actionAddOneUnit => 'Añadir una unidad';

  @override
  String semanticsBackTo(String label) {
    return 'Volver a $label';
  }

  @override
  String get semanticsShowPassword => 'Mostrar contraseña';

  @override
  String get semanticsHidePassword => 'Ocultar contraseña';

  @override
  String get semanticsLess => 'Menos';

  @override
  String get semanticsMore => 'Más';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabStock => 'Stock';

  @override
  String get tabOrders => 'Pedidos';

  @override
  String get tabRules => 'Reglas';

  @override
  String get tabAssistant => 'Asistente';

  @override
  String get homeTitle => 'Hoy';

  @override
  String get homeToApprove => 'Para aprobar';

  @override
  String get homeRunningOutSoon => 'Se agota pronto';

  @override
  String get homeAllInOrder => 'Todo en orden';

  @override
  String get homeAllInOrderDetail =>
      'Ningún producto está por debajo del mínimo';

  @override
  String get homeAgentWorking => 'Trabajando…';

  @override
  String get homeAgentActive => 'Agente activo';

  @override
  String homeBudgetOfMonth(String month) {
    return 'Presupuesto de $month';
  }

  @override
  String homeRemaining(String amount) {
    return 'Quedan $amount';
  }

  @override
  String get homeAgentTitle => 'Agente de reposición';

  @override
  String get homeAgentDescription =>
      'Revisa tu stock, prepara pedidos y págalos con PayPal dentro de tus reglas.';

  @override
  String get homeReviewing => 'Revisando…';

  @override
  String get homeNeedsApproval => 'Necesita tu aprobación';

  @override
  String get homeAgentFailed => 'Algo salió mal';

  @override
  String get homeStockReview => 'Revisión del stock';

  @override
  String get stockSearchPlaceholder => 'Buscar por nombre o UID';

  @override
  String get catalogSearchPlaceholder => 'Buscar por nombre o UID';

  @override
  String get catalogFilterAll => 'Todos';

  @override
  String get catalogEmptyTitle => 'No hay productos';

  @override
  String get catalogEmptyHint =>
      'Prueba con otro nombre o cambia de proveedor.';

  @override
  String get catalogTitle => 'Catálogo de proveedores';

  @override
  String get catalogAddProducts => 'Añadir productos al stock';

  @override
  String get catalogAddProductsHint =>
      'Busca en el catálogo de tus proveedores';

  @override
  String get catalogAddToStock => 'Añadir';

  @override
  String get catalogQuantity => 'Cantidad';

  @override
  String get catalogAddToCart => 'Añadir al carrito';

  @override
  String get catalogCartTitle => 'Carrito';

  @override
  String get catalogCartTotal => 'Total';

  @override
  String get catalogViewCart => 'Ver carrito';

  @override
  String get catalogOrdersPerSupplier => 'Se creará un pedido por proveedor.';

  @override
  String catalogOrdersCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pedidos creados, uno por proveedor',
      one: '1 pedido creado',
    );
    return '$_temp0';
  }

  @override
  String catalogCartQuantity(int qty) {
    return '$qty ud.';
  }

  @override
  String catalogCartItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get catalogOrderButton => 'Tramitar pedido';

  @override
  String get catalogOrderCreated =>
      'Pedido creado. Apruébalo para pagar y sumar el stock.';

  @override
  String get stockFilterAll => 'Todos';

  @override
  String get stockFilterLow => 'Bajo mínimo';

  @override
  String get stockFilterTransit => 'En camino';

  @override
  String get stockEmptyTitle => 'Aún no hay productos';

  @override
  String get stockEmptyFilterTitle => 'Nada con ese filtro';

  @override
  String get stockEmptyMessage =>
      'Los catálogos de tus proveedores aparecerán aquí.';

  @override
  String stockProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos',
      one: '1 producto',
      zero: 'Ningún producto',
    );
    return '$_temp0';
  }

  @override
  String get stockStatusTransit => 'En camino';

  @override
  String get stockStatusOut => 'Agotado';

  @override
  String get stockStatusLow => 'Bajo mínimo';

  @override
  String get stockStatusOk => 'Correcto';

  @override
  String stockUnitsMin(int stock, String unit, int min) {
    return '$stock $unit · mín. $min';
  }

  @override
  String get stockUpdated => 'Stock actualizado';

  @override
  String stockUpdatedMessage(String name, int stock, String unit) {
    return '$name: $stock $unit.';
  }

  @override
  String stockEditorUid(String uid, int min, String unit) {
    return '$uid · mín. $min $unit';
  }

  @override
  String get ordersTitle => 'Pedidos';

  @override
  String ordersSpentInMonth(String month) {
    return 'Gastado en $month';
  }

  @override
  String get ordersCreatedByAgent => 'Creados por el agente';

  @override
  String ordersCreatedByAgentValue(int count, int total) {
    return '$count de $total';
  }

  @override
  String get ordersHistory => 'Historial';

  @override
  String get ordersEmptyTitle => 'Todavía no hay pedidos';

  @override
  String get ordersEmptyMessage =>
      'Pulsa «Revisar stock ahora» en Inicio para que el agente prepare el primero.';

  @override
  String get ordersDeliveryQuestion => '¿Ha llegado el pedido?';

  @override
  String ordersCheckDelivery(String supplier) {
    return 'Comprueba la entrega de $supplier';
  }

  @override
  String get ordersCreatedByAgentWord => 'agente';

  @override
  String get ordersCreatedByYouWord => 'tú';

  @override
  String get statusDraft => 'Por aprobar';

  @override
  String get statusPendingApproval => 'Nuevo stock por aprobar';

  @override
  String get statusApproved => 'Aprobado';

  @override
  String get statusPaying => 'Pagando…';

  @override
  String get statusPaid => 'Pagado con PayPal';

  @override
  String get statusInvoiced => 'Facturado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusRejected => 'Rechazado';

  @override
  String get statusPaymentFailed => 'Pago fallido';

  @override
  String reasonOverMaxPerOrder(String amount) {
    return 'Supera el máximo de $amount por pedido';
  }

  @override
  String reasonOverMonthlyLimit(String amount) {
    return 'Supera tu tope de $amount al mes';
  }

  @override
  String get reasonAnyOrderApproval =>
      'Este pedido requiere tu aprobación antes de continuar';

  @override
  String get authPaypalSameEmail => 'Usar el mismo correo que la cuenta';

  @override
  String reasonOverApprovalThreshold(String amount) {
    return 'Supera $amount sin aprobación';
  }

  @override
  String get reasonNoAmount => 'El pedido no tiene importe';

  @override
  String get reasonSupplierNotAllowed =>
      'El proveedor no está en tu lista de permitidos';

  @override
  String get orderUnavailable => 'Este pedido ya no está disponible';

  @override
  String orderTitle(String supplier) {
    return 'Pedido a $supplier';
  }

  @override
  String get orderCreatedByAgent => 'Lo preparó el agente';

  @override
  String get orderCreatedByYou => 'Lo creaste tú';

  @override
  String orderUnitPrice(String price, String uid) {
    return '$price / ud · $uid';
  }

  @override
  String get orderTotal => 'Total';

  @override
  String get orderWhatAgentDecided => 'Qué decidió el agente';

  @override
  String orderConfidence(int percent) {
    return 'confianza $percent %';
  }

  @override
  String get orderPaypalPayment => 'Pago PayPal';

  @override
  String get orderPaymentDate => 'Fecha de pago';

  @override
  String get orderPaymentStatusSent => 'enviado';

  @override
  String get orderBlockedByRules => 'Bloqueado por tus reglas';

  @override
  String get orderBlockedHint =>
      'Cambia tus reglas en la pestaña Reglas si quieres permitirlo.';

  @override
  String orderApproveHint(String supplier) {
    return 'Al aprobar, el servidor paga a $supplier y genera la factura.';
  }

  @override
  String orderSpendAfterPayment(String month) {
    return 'Gasto de $month tras el pago';
  }

  @override
  String orderSpendOf(String spent, String limit) {
    return '$spent de $limit';
  }

  @override
  String get orderLegendSpent => 'Ya gastado';

  @override
  String get orderLegendThisOrder => 'Este pedido';

  @override
  String get orderPaymentSent => 'Pago enviado';

  @override
  String orderPaymentSentMessage(String amount, String supplier) {
    return '$amount enviados a $supplier con PayPal.';
  }

  @override
  String get orderPaymentFailed => 'No se pudo pagar';

  @override
  String get orderPriceChangedTitle => 'El precio ha cambiado';

  @override
  String orderPriceChangedMessage(String newTotal, String previousTotal) {
    return 'El nuevo total es $newTotal (antes $previousTotal). Se cobrará el precio vigente del proveedor.';
  }

  @override
  String actionPayNewTotal(String amount) {
    return 'Pagar $amount';
  }

  @override
  String get orderRejectQuestion => '¿Rechazar el pedido?';

  @override
  String orderRejectMessage(String supplier) {
    return 'El agente no pagará a $supplier.';
  }

  @override
  String get orderRejected => 'Pedido rechazado';

  @override
  String get orderRejectFailed => 'No se pudo rechazar';

  @override
  String deliveryTitle(String supplier) {
    return 'Entrega de $supplier';
  }

  @override
  String get deliverySubtitle =>
      'Ajusta lo que ha llegado. Lo que falte se puede reclamar.';

  @override
  String get deliveryComingSoon => 'Próximamente';

  @override
  String get deliveryComingSoonMessage =>
      'La lectura del albarán con IA llegará pronto.';

  @override
  String get deliveryPhoto => 'Foto del albarán';

  @override
  String deliveryOrderedMissing(int qty, int missing) {
    return 'Pedido $qty · faltan $missing';
  }

  @override
  String deliveryOrderedComplete(int qty) {
    return 'Pedido $qty · completo';
  }

  @override
  String get deliveryRegistered => 'Entrega registrada';

  @override
  String get deliveryRegisteredMessage =>
      'Se ha guardado lo que llegó del pedido.';

  @override
  String deliveryClaim(int units, String amount) {
    return 'Reclamar $units uds · $amount';
  }

  @override
  String get deliveryClaimReady => 'Reclamación preparada';

  @override
  String get deliveryClaimMessage => 'Avísale de las unidades que faltan.';

  @override
  String get assistantTitle => 'Asistente';

  @override
  String get assistantSubtitle => 'Tu agente de reposición';

  @override
  String get assistantGreeting =>
      'Hola. Reviso tu stock, preparo pedidos a tus proveedores y los pago con PayPal, siempre dentro de tus reglas de gasto.';

  @override
  String get assistantChipReview => 'Revisa el stock ahora';

  @override
  String get assistantChipPending => '¿Qué tengo por aprobar?';

  @override
  String get assistantChipSpent => '¿Cuánto llevo gastado?';

  @override
  String get assistantInputHint => 'Pregunta lo que quieras';

  @override
  String get assistantTyping => 'Revisando tu stock…';

  @override
  String get assistantSend => 'Enviar';

  @override
  String get assistantPendingEmpty =>
      'No tienes pedidos esperando tu aprobación.';

  @override
  String assistantPendingList(int count, String list) {
    return 'Tienes $count por aprobar: $list. Los encuentras en Inicio.';
  }

  @override
  String get assistantPendingQuestion => '¿Qué tengo por aprobar?';

  @override
  String get assistantSpentQuestion => '¿Cuánto llevo gastado?';

  @override
  String assistantSpentAnswer(
    String spent,
    String month,
    String limit,
    String remaining,
  ) {
    return 'Llevas **$spent** gastados en $month de un tope de **$limit**. Te quedan **$remaining**.';
  }

  @override
  String get rulesTitle => 'Reglas';

  @override
  String get rulesSubtitle => 'El agente solo paga si se cumplen todas';

  @override
  String get rulesSpending => 'Gasto';

  @override
  String get rulesAccount => 'Cuenta';

  @override
  String get rulesMonthlyLimit => 'Tope mensual';

  @override
  String rulesMonthlyLimitText(String amount) {
    return 'No gastes más de $amount al mes';
  }

  @override
  String rulesMonthlySpent(String amount) {
    return 'Llevas $amount';
  }

  @override
  String get rulesMaxPerOrder => 'Máximo por pedido';

  @override
  String rulesMaxPerOrderText(String amount) {
    return 'Ningún pedido puede pasar de $amount';
  }

  @override
  String get rulesApproval => 'Pide aprobación';

  @override
  String get rulesApprovalTextAny => 'Pregúntame por cualquier pedido';

  @override
  String rulesApprovalTextAbove(String amount) {
    return 'Si un pedido pasa de $amount, pregúntame';
  }

  @override
  String get rulesSuppliers => 'Proveedores';

  @override
  String get rulesSuppliersTextAny => 'Puedes comprar a cualquier proveedor';

  @override
  String rulesSuppliersTextList(String list) {
    return 'Compra solo a $list';
  }

  @override
  String get rulesHint =>
      'Toca una regla para cambiarla. Las reglas se comprueban en el sistema, no en la IA.';

  @override
  String get rulesSession => 'Sesión';

  @override
  String get rulesAppearance => 'Apariencia';

  @override
  String get rulesThemeAuto => 'Auto';

  @override
  String get rulesThemeLight => 'Claro';

  @override
  String get rulesThemeDark => 'Oscuro';

  @override
  String get rulesLanguage => 'Idioma';

  @override
  String get rulesLanguageAuto => 'Auto';

  @override
  String get rulesLanguageSpanish => 'Español';

  @override
  String get rulesLanguageEnglish => 'English';

  @override
  String get rulesSounds => 'Sonidos';

  @override
  String get rulesSignOutQuestion => '¿Cerrar sesión?';

  @override
  String get rulesSignOutCancel => 'Cancelar';

  @override
  String get rulesSignOutConfirm => 'Cerrar sesión';

  @override
  String get rulesSaved => 'Reglas guardadas';

  @override
  String get rulesSavedMessage =>
      'Tus límites de gasto y proveedores ya están aplicados.';

  @override
  String get rulesSaveFailed => 'No se pudieron guardar las reglas';

  @override
  String get rulesMonthlyLimitSheetHint =>
      'No puede ser menor que el máximo por pedido.';

  @override
  String get rulesMaxPerOrderSheetHint => 'Tiene que ser mayor que 0.';

  @override
  String get rulesApprovalSheetTitle => 'Pedir aprobación a partir de';

  @override
  String get rulesApprovalSheetHint =>
      'Con 0 me preguntas por cualquier pedido.';

  @override
  String get rulesSuppliersSheetTitle => 'Proveedores permitidos';

  @override
  String get rulesSuppliersSheetHint =>
      'Si no marcas ninguno, el agente puede comprar a todos.';

  @override
  String get authEmail => 'Correo';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authPasswordHint => 'Mínimo 6 caracteres';

  @override
  String get authConfirmPassword => 'Repite la contraseña';

  @override
  String get authStoreName => 'Nombre de tu tienda';

  @override
  String get authStoreNameHint => 'Tienda Lumbre';

  @override
  String get authPaypalEmail => 'Correo de PayPal (opcional)';

  @override
  String get authPaypalEmailHint => 'pagos@tutienda.com';

  @override
  String get authPaypalEmailHelp =>
      'Aquí recibirás los pagos de los pedidos. Si lo dejas vacío, los pedidos no se podrán pagar automáticamente.';

  @override
  String get authPaypalSectionTitle => 'Cobros con PayPal';

  @override
  String get authPaypalEmailInvalid => 'El correo de PayPal no parece válido.';

  @override
  String get authEmailHint => 'tu@tienda.com';

  @override
  String get authSignInFailed => 'No se pudo iniciar sesión';

  @override
  String get authMissingFields => 'Faltan datos';

  @override
  String get authMissingFieldsBody => 'Completa el correo y la contraseña.';

  @override
  String get authMissingEmail => 'Falta el correo';

  @override
  String get authMissingEmailBody => 'Escribe tu correo primero.';

  @override
  String get authEmailSent => 'Correo enviado';

  @override
  String get authEmailSentBody =>
      'Si el correo existe, te enviamos un enlace de recuperación.';

  @override
  String get authResendEmail => 'Reenviar correo de confirmación';

  @override
  String get authResendEmailSent => 'Correo reenviado';

  @override
  String get authResendEmailSentBody =>
      'Te hemos enviado otro correo de confirmación. Revisa tu bandeja de entrada o el spam.';

  @override
  String get authFirstTime => '¿Primera vez en Restock?';

  @override
  String get authFirstTimeBody =>
      'Crea tu tienda y deja que el agente reponga el stock.';

  @override
  String get authCreateTitle => 'Crear cuenta';

  @override
  String get authCreateSubtitle =>
      'Crea tu tienda y empieza a reponer en segundos';

  @override
  String get authCreateFailed => 'No se pudo crear la cuenta';

  @override
  String get authAccountCreated => 'Cuenta creada';

  @override
  String get authCreateMissingFieldsBody =>
      'Completa el correo y las dos contraseñas.';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authPasswordTooShortTitle => 'Contraseña corta';

  @override
  String get authPasswordsMismatch => 'Las contraseñas no coinciden.';

  @override
  String get authPasswordsMismatchTitle => 'No coinciden';

  @override
  String get authCreateFooter =>
      'Crear la tienda es gratis. Solo pagas los pedidos que el agente prepare y tú apruebes, dentro de tus reglas.';

  @override
  String get errorLoadData => 'No se pudieron cargar tus datos';

  @override
  String get errorAgentBusy => 'El agente ya está trabajando.';

  @override
  String get decisionOrderCreated =>
      'Preparé un pedido de reposición con tu stock bajo.';

  @override
  String get decisionNoAction => 'Revisé el stock: no hacía falta pedir nada.';

  @override
  String get decisionBlocked =>
      'Quise pedir, pero tus reglas de gasto lo bloquearon.';

  @override
  String get decisionFailed =>
      'La revisión falló. Inténtalo de nuevo en un momento.';

  @override
  String get decisionAutoApproved =>
      'Hice un pedido dentro de tus reglas y lo pagué con PayPal.';

  @override
  String get decisionRequiresApproval =>
      'Preparé un pedido que necesita tu aprobación.';

  @override
  String decisionGeneric(String decision) {
    return 'Revisión del agente: $decision';
  }

  @override
  String get agentChatFallback =>
      'De momento sé revisar tu stock, proponer pedidos y pagarlos con PayPal dentro de tus reglas. Pulsa «Revisa el stock ahora» y me pongo con ello.';

  @override
  String get agentChatTrigger => 'Revisa el stock ahora';

  @override
  String dateToday(String time) {
    return 'Hoy $time';
  }

  @override
  String dateYesterday(String time) {
    return 'Ayer $time';
  }

  @override
  String get dashboardSignedIn => 'Sesión iniciada';

  @override
  String get dashboardUser => 'Usuario';

  @override
  String dashboardStore(String store) {
    return 'Tienda: $store';
  }

  @override
  String get dashboardNextStep => 'Siguiente paso: catálogo, pedidos y agente.';

  @override
  String get errorAuthUserMissing => 'No se pudo obtener el usuario';

  @override
  String get errorAuthSignInFailed => 'No se pudo iniciar sesión';

  @override
  String get errorAuthSignUpFailed => 'No se pudo registrar';

  @override
  String get errorAuthConfirmEmail =>
      'Cuenta creada. Revisa tu correo para confirmarla e inicia sesión.';

  @override
  String get errorAuthSignUpRateLimited =>
      'No se pudo crear la cuenta: se alcanzó el límite de intentos o de envío de correos. Espera un rato y vuelve a intentarlo.';

  @override
  String get errorAuthSignOutFailed =>
      'No se pudo cerrar sesión. Inténtalo de nuevo.';

  @override
  String get errorAuthResetEmailFailed =>
      'No se pudo enviar el correo de recuperación.';

  @override
  String get errorAuthInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get errorAuthEmailTaken => 'Ese correo ya está registrado';

  @override
  String get errorAuthWeakPassword =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get errorAuthEmailNotConfirmed => 'Confirma tu correo antes de entrar';

  @override
  String get errorAuthResendConfirmFailed =>
      'No se pudo reenviar el correo de confirmación.';

  @override
  String get errorAuthTooManyAttempts =>
      'Demasiados intentos. Espera un rato y vuelve a intentarlo.';

  @override
  String get errorAuthValidationFailed => 'Revisa el correo y la contraseña';

  @override
  String get errorSessionExpired => 'Sesión caducada. Vuelve a iniciar sesión.';

  @override
  String get errorStoreLoadFailed => 'No se pudo cargar la tienda';

  @override
  String get errorStoreUpdateFailed => 'No se pudo actualizar la tienda';

  @override
  String get errorStoreNotFound => 'No se encontró la tienda del usuario.';

  @override
  String get errorStoreNameEmpty =>
      'El nombre de la tienda no puede estar vacío.';

  @override
  String get errorRulesNotFound => 'No se encontraron las reglas de gasto.';

  @override
  String get errorRulesLoadFailed =>
      'No se pudieron cargar las reglas de gasto';

  @override
  String get errorRulesSaveFailed =>
      'No se pudieron guardar las reglas de gasto';

  @override
  String get errorRuleMaxPerOrderInvalid =>
      'El máximo por pedido debe ser mayor que 0.';

  @override
  String get errorRuleMonthlyBelowMax =>
      'El límite mensual no puede ser menor que el máximo por pedido.';

  @override
  String get errorRuleApprovalAboveMax =>
      'El umbral de aprobación no puede superar el máximo por pedido.';

  @override
  String get errorOrdersLoadFailed => 'No se pudieron cargar los pedidos';

  @override
  String get errorOrderLoadFailed => 'No se pudo cargar el pedido';

  @override
  String get errorOrderCreateFailed => 'No se pudo crear el pedido';

  @override
  String get errorOrderSpentFailed => 'No se pudo calcular el gasto mensual';

  @override
  String get errorOrderApproveFailed => 'No se pudo aprobar el pedido';

  @override
  String get errorOrderRejectFailed => 'No se pudo rechazar el pedido';

  @override
  String get errorOrderAmountFailed =>
      'No se pudo comprobar el importe del pedido';

  @override
  String get errorOrderMissing => 'Falta el pedido.';

  @override
  String get errorOrderNotFound => 'Ese pedido ya no existe.';

  @override
  String get errorOrderEmpty => 'El pedido no tiene líneas.';

  @override
  String get errorOrderBlocked => 'El pedido está bloqueado por tus reglas.';

  @override
  String errorOrderItemInvalidQty(String uid) {
    return 'Cantidad no válida para $uid.';
  }

  @override
  String errorOrderProductMissing(String uid) {
    return 'No encuentro el producto $uid en el catálogo.';
  }

  @override
  String errorOrderProductInactive(String name) {
    return 'El producto $name ya no está activo.';
  }

  @override
  String get errorInvoiceLoadFailed => 'No se pudo cargar la factura';

  @override
  String get errorSuppliersLoadFailed =>
      'No se pudieron cargar los proveedores';

  @override
  String get errorSupplierLoadFailed => 'No se pudo cargar el proveedor';

  @override
  String get errorCatalogLoadFailed => 'No se pudo cargar el catálogo';

  @override
  String get errorProductSearchFailed => 'No se pudo buscar el producto';

  @override
  String get errorProductsLoadFailed => 'No se pudieron cargar los productos';

  @override
  String get errorLowStockLoadFailed => 'No se pudo cargar el stock bajo';

  @override
  String get errorStockUpdateFailed => 'No se pudo actualizar el stock';

  @override
  String get errorProductMissing => 'Falta el producto.';

  @override
  String errorProductNotFound(String uid) {
    return 'No existe ningún producto con UID $uid.';
  }

  @override
  String get errorProductUidMissing => 'Introduce un UID.';

  @override
  String get errorStockNegative => 'El stock no puede ser negativo.';

  @override
  String get errorAgentUnreachable => 'El agente no respondió';

  @override
  String get errorAgentFailed => 'Error del agente';

  @override
  String get errorAgentRunsLoadFailed =>
      'No se pudieron cargar las ejecuciones';

  @override
  String get errorAgentStoreMissing => 'Falta la tienda.';

  @override
  String get errorPreviewNoSignOut => 'En la vista previa no se cierra sesión.';
}
