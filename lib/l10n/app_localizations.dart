import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Restock'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Pedidos automáticos con IA + PayPal'**
  String get appTagline;

  /// No description provided for @configErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración incompleta'**
  String get configErrorTitle;

  /// No description provided for @actionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get actionBack;

  /// No description provided for @actionOk.
  ///
  /// In es, this message translates to:
  /// **'Vale'**
  String get actionOk;

  /// No description provided for @actionSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get actionSend;

  /// No description provided for @actionSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get actionSignOut;

  /// No description provided for @actionCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear una cuenta'**
  String get actionCreateAccount;

  /// No description provided for @actionSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get actionSignIn;

  /// No description provided for @actionCreateMyStore.
  ///
  /// In es, this message translates to:
  /// **'Crear mi tienda'**
  String get actionCreateMyStore;

  /// No description provided for @actionAlreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get actionAlreadyHaveAccount;

  /// No description provided for @actionForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get actionForgotPassword;

  /// No description provided for @actionApproveAndPay.
  ///
  /// In es, this message translates to:
  /// **'Aprobar y pagar con PayPal'**
  String get actionApproveAndPay;

  /// No description provided for @actionReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get actionReject;

  /// No description provided for @actionConfirmDelivery.
  ///
  /// In es, this message translates to:
  /// **'Confirmar entrega'**
  String get actionConfirmDelivery;

  /// No description provided for @actionReviewStockNow.
  ///
  /// In es, this message translates to:
  /// **'Revisar stock ahora'**
  String get actionReviewStockNow;

  /// No description provided for @actionRemoveOneUnit.
  ///
  /// In es, this message translates to:
  /// **'Quitar una unidad'**
  String get actionRemoveOneUnit;

  /// No description provided for @actionAddOneUnit.
  ///
  /// In es, this message translates to:
  /// **'Añadir una unidad'**
  String get actionAddOneUnit;

  /// No description provided for @semanticsBackTo.
  ///
  /// In es, this message translates to:
  /// **'Volver a {label}'**
  String semanticsBackTo(String label);

  /// No description provided for @semanticsShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get semanticsShowPassword;

  /// No description provided for @semanticsHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get semanticsHidePassword;

  /// No description provided for @semanticsLess.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get semanticsLess;

  /// No description provided for @semanticsMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get semanticsMore;

  /// No description provided for @tabHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get tabHome;

  /// No description provided for @tabStock.
  ///
  /// In es, this message translates to:
  /// **'Stock'**
  String get tabStock;

  /// No description provided for @tabOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get tabOrders;

  /// No description provided for @tabRules.
  ///
  /// In es, this message translates to:
  /// **'Reglas'**
  String get tabRules;

  /// No description provided for @tabAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get tabAssistant;

  /// No description provided for @homeTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get homeTitle;

  /// No description provided for @homeToApprove.
  ///
  /// In es, this message translates to:
  /// **'Para aprobar'**
  String get homeToApprove;

  /// No description provided for @homeRunningOutSoon.
  ///
  /// In es, this message translates to:
  /// **'Se agota pronto'**
  String get homeRunningOutSoon;

  /// No description provided for @homeAllInOrder.
  ///
  /// In es, this message translates to:
  /// **'Todo en orden'**
  String get homeAllInOrder;

  /// No description provided for @homeAllInOrderDetail.
  ///
  /// In es, this message translates to:
  /// **'Ningún producto está por debajo del mínimo'**
  String get homeAllInOrderDetail;

  /// No description provided for @homeAgentWorking.
  ///
  /// In es, this message translates to:
  /// **'Trabajando…'**
  String get homeAgentWorking;

  /// No description provided for @homeAgentActive.
  ///
  /// In es, this message translates to:
  /// **'Agente activo'**
  String get homeAgentActive;

  /// No description provided for @homeBudgetOfMonth.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto de {month}'**
  String homeBudgetOfMonth(String month);

  /// No description provided for @homeRemaining.
  ///
  /// In es, this message translates to:
  /// **'Quedan {amount}'**
  String homeRemaining(String amount);

  /// No description provided for @homeAgentTitle.
  ///
  /// In es, this message translates to:
  /// **'Agente de reposición'**
  String get homeAgentTitle;

  /// No description provided for @homeAgentDescription.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu stock, prepara pedidos y págalos con PayPal dentro de tus reglas.'**
  String get homeAgentDescription;

  /// No description provided for @homeReviewing.
  ///
  /// In es, this message translates to:
  /// **'Revisando…'**
  String get homeReviewing;

  /// No description provided for @homeNeedsApproval.
  ///
  /// In es, this message translates to:
  /// **'Necesita tu aprobación'**
  String get homeNeedsApproval;

  /// No description provided for @homeAgentFailed.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get homeAgentFailed;

  /// No description provided for @homeStockReview.
  ///
  /// In es, this message translates to:
  /// **'Revisión del stock'**
  String get homeStockReview;

  /// No description provided for @stockSearchPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o UID'**
  String get stockSearchPlaceholder;

  /// No description provided for @stockFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get stockFilterAll;

  /// No description provided for @stockFilterLow.
  ///
  /// In es, this message translates to:
  /// **'Bajo mínimo'**
  String get stockFilterLow;

  /// No description provided for @stockFilterTransit.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get stockFilterTransit;

  /// No description provided for @stockEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay productos'**
  String get stockEmptyTitle;

  /// No description provided for @stockEmptyFilterTitle.
  ///
  /// In es, this message translates to:
  /// **'Nada con ese filtro'**
  String get stockEmptyFilterTitle;

  /// No description provided for @stockEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Los catálogos de tus proveedores aparecerán aquí.'**
  String get stockEmptyMessage;

  /// No description provided for @stockProductCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Ningún producto} =1{1 producto} other{{count} productos}}'**
  String stockProductCount(int count);

  /// No description provided for @stockStatusTransit.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get stockStatusTransit;

  /// No description provided for @stockStatusOut.
  ///
  /// In es, this message translates to:
  /// **'Agotado'**
  String get stockStatusOut;

  /// No description provided for @stockStatusLow.
  ///
  /// In es, this message translates to:
  /// **'Bajo mínimo'**
  String get stockStatusLow;

  /// No description provided for @stockStatusOk.
  ///
  /// In es, this message translates to:
  /// **'Correcto'**
  String get stockStatusOk;

  /// No description provided for @stockUnitsMin.
  ///
  /// In es, this message translates to:
  /// **'{stock} {unit} · mín. {min}'**
  String stockUnitsMin(int stock, String unit, int min);

  /// No description provided for @stockUpdated.
  ///
  /// In es, this message translates to:
  /// **'Stock actualizado'**
  String get stockUpdated;

  /// No description provided for @stockUpdatedMessage.
  ///
  /// In es, this message translates to:
  /// **'{name}: {stock} {unit}.'**
  String stockUpdatedMessage(String name, int stock, String unit);

  /// No description provided for @stockEditorUid.
  ///
  /// In es, this message translates to:
  /// **'{uid} · mín. {min} {unit}'**
  String stockEditorUid(String uid, int min, String unit);

  /// No description provided for @ordersTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get ordersTitle;

  /// No description provided for @ordersSpentInMonth.
  ///
  /// In es, this message translates to:
  /// **'Gastado en {month}'**
  String ordersSpentInMonth(String month);

  /// No description provided for @ordersCreatedByAgent.
  ///
  /// In es, this message translates to:
  /// **'Creados por el agente'**
  String get ordersCreatedByAgent;

  /// No description provided for @ordersCreatedByAgentValue.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total}'**
  String ordersCreatedByAgentValue(int count, int total);

  /// No description provided for @ordersHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get ordersHistory;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay pedidos'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyMessage.
  ///
  /// In es, this message translates to:
  /// **'Pulsa «Revisar stock ahora» en Inicio para que el agente prepare el primero.'**
  String get ordersEmptyMessage;

  /// No description provided for @ordersDeliveryQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Ha llegado el pedido?'**
  String get ordersDeliveryQuestion;

  /// No description provided for @ordersCheckDelivery.
  ///
  /// In es, this message translates to:
  /// **'Comprueba la entrega de {supplier}'**
  String ordersCheckDelivery(String supplier);

  /// No description provided for @ordersCreatedByAgentWord.
  ///
  /// In es, this message translates to:
  /// **'agente'**
  String get ordersCreatedByAgentWord;

  /// No description provided for @ordersCreatedByYouWord.
  ///
  /// In es, this message translates to:
  /// **'tú'**
  String get ordersCreatedByYouWord;

  /// No description provided for @statusDraft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get statusDraft;

  /// No description provided for @statusPendingApproval.
  ///
  /// In es, this message translates to:
  /// **'Por aprobar'**
  String get statusPendingApproval;

  /// No description provided for @statusApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get statusApproved;

  /// No description provided for @statusPaying.
  ///
  /// In es, this message translates to:
  /// **'Pagando…'**
  String get statusPaying;

  /// No description provided for @statusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado con PayPal'**
  String get statusPaid;

  /// No description provided for @statusInvoiced.
  ///
  /// In es, this message translates to:
  /// **'Facturado'**
  String get statusInvoiced;

  /// No description provided for @statusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get statusCompleted;

  /// No description provided for @statusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get statusRejected;

  /// No description provided for @statusPaymentFailed.
  ///
  /// In es, this message translates to:
  /// **'Pago fallido'**
  String get statusPaymentFailed;

  /// No description provided for @reasonOverMaxPerOrder.
  ///
  /// In es, this message translates to:
  /// **'Supera el máximo de {amount} por pedido'**
  String reasonOverMaxPerOrder(String amount);

  /// No description provided for @reasonOverMonthlyLimit.
  ///
  /// In es, this message translates to:
  /// **'Supera tu tope de {amount} al mes'**
  String reasonOverMonthlyLimit(String amount);

  /// No description provided for @reasonAnyOrderApproval.
  ///
  /// In es, this message translates to:
  /// **'Me preguntas por cualquier pedido'**
  String get reasonAnyOrderApproval;

  /// No description provided for @reasonOverApprovalThreshold.
  ///
  /// In es, this message translates to:
  /// **'Supera {amount} sin aprobación'**
  String reasonOverApprovalThreshold(String amount);

  /// No description provided for @reasonNoAmount.
  ///
  /// In es, this message translates to:
  /// **'El pedido no tiene importe'**
  String get reasonNoAmount;

  /// No description provided for @reasonSupplierNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'El proveedor no está en tu lista de permitidos'**
  String get reasonSupplierNotAllowed;

  /// No description provided for @orderUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este pedido ya no está disponible'**
  String get orderUnavailable;

  /// No description provided for @orderTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedido a {supplier}'**
  String orderTitle(String supplier);

  /// No description provided for @orderCreatedByAgent.
  ///
  /// In es, this message translates to:
  /// **'Lo preparó el agente'**
  String get orderCreatedByAgent;

  /// No description provided for @orderCreatedByYou.
  ///
  /// In es, this message translates to:
  /// **'Lo creaste tú'**
  String get orderCreatedByYou;

  /// No description provided for @orderUnitPrice.
  ///
  /// In es, this message translates to:
  /// **'{price} / ud · {uid}'**
  String orderUnitPrice(String price, String uid);

  /// No description provided for @orderTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// No description provided for @orderWhatAgentDecided.
  ///
  /// In es, this message translates to:
  /// **'Qué decidió el agente'**
  String get orderWhatAgentDecided;

  /// No description provided for @orderConfidence.
  ///
  /// In es, this message translates to:
  /// **'confianza {percent} %'**
  String orderConfidence(int percent);

  /// No description provided for @orderPaypalPayment.
  ///
  /// In es, this message translates to:
  /// **'Pago PayPal'**
  String get orderPaypalPayment;

  /// No description provided for @orderPaymentDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de pago'**
  String get orderPaymentDate;

  /// No description provided for @orderPaymentStatusSent.
  ///
  /// In es, this message translates to:
  /// **'enviado'**
  String get orderPaymentStatusSent;

  /// No description provided for @orderBlockedByRules.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado por tus reglas'**
  String get orderBlockedByRules;

  /// No description provided for @orderBlockedHint.
  ///
  /// In es, this message translates to:
  /// **'Cambia tus reglas en la pestaña Reglas si quieres permitirlo.'**
  String get orderBlockedHint;

  /// No description provided for @orderApproveHint.
  ///
  /// In es, this message translates to:
  /// **'Al aprobar, el servidor paga a {supplier} y genera la factura.'**
  String orderApproveHint(String supplier);

  /// No description provided for @orderSpendAfterPayment.
  ///
  /// In es, this message translates to:
  /// **'Gasto de {month} tras el pago'**
  String orderSpendAfterPayment(String month);

  /// No description provided for @orderSpendOf.
  ///
  /// In es, this message translates to:
  /// **'{spent} de {limit}'**
  String orderSpendOf(String spent, String limit);

  /// No description provided for @orderLegendSpent.
  ///
  /// In es, this message translates to:
  /// **'Ya gastado'**
  String get orderLegendSpent;

  /// No description provided for @orderLegendThisOrder.
  ///
  /// In es, this message translates to:
  /// **'Este pedido'**
  String get orderLegendThisOrder;

  /// No description provided for @orderPaymentSent.
  ///
  /// In es, this message translates to:
  /// **'Pago enviado'**
  String get orderPaymentSent;

  /// No description provided for @orderPaymentSentMessage.
  ///
  /// In es, this message translates to:
  /// **'{amount} enviados a {supplier} con PayPal.'**
  String orderPaymentSentMessage(String amount, String supplier);

  /// No description provided for @orderPaymentFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo pagar'**
  String get orderPaymentFailed;

  /// No description provided for @orderRejectQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Rechazar el pedido?'**
  String get orderRejectQuestion;

  /// No description provided for @orderRejectMessage.
  ///
  /// In es, this message translates to:
  /// **'El agente no pagará a {supplier}.'**
  String orderRejectMessage(String supplier);

  /// No description provided for @orderRejected.
  ///
  /// In es, this message translates to:
  /// **'Pedido rechazado'**
  String get orderRejected;

  /// No description provided for @orderRejectFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo rechazar'**
  String get orderRejectFailed;

  /// No description provided for @deliveryTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrega de {supplier}'**
  String deliveryTitle(String supplier);

  /// No description provided for @deliverySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ajusta lo que ha llegado. Lo que falte se puede reclamar.'**
  String get deliverySubtitle;

  /// No description provided for @deliveryComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get deliveryComingSoon;

  /// No description provided for @deliveryComingSoonMessage.
  ///
  /// In es, this message translates to:
  /// **'La lectura del albarán con IA llegará pronto.'**
  String get deliveryComingSoonMessage;

  /// No description provided for @deliveryPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto del albarán'**
  String get deliveryPhoto;

  /// No description provided for @deliveryOrderedMissing.
  ///
  /// In es, this message translates to:
  /// **'Pedido {qty} · faltan {missing}'**
  String deliveryOrderedMissing(int qty, int missing);

  /// No description provided for @deliveryOrderedComplete.
  ///
  /// In es, this message translates to:
  /// **'Pedido {qty} · completo'**
  String deliveryOrderedComplete(int qty);

  /// No description provided for @deliveryRegistered.
  ///
  /// In es, this message translates to:
  /// **'Entrega registrada'**
  String get deliveryRegistered;

  /// No description provided for @deliveryRegisteredMessage.
  ///
  /// In es, this message translates to:
  /// **'Se ha guardado lo que llegó del pedido.'**
  String get deliveryRegisteredMessage;

  /// No description provided for @deliveryClaim.
  ///
  /// In es, this message translates to:
  /// **'Reclamar {units} uds · {amount}'**
  String deliveryClaim(int units, String amount);

  /// No description provided for @deliveryClaimReady.
  ///
  /// In es, this message translates to:
  /// **'Reclamación preparada'**
  String get deliveryClaimReady;

  /// No description provided for @deliveryClaimMessage.
  ///
  /// In es, this message translates to:
  /// **'Avísale de las unidades que faltan.'**
  String get deliveryClaimMessage;

  /// No description provided for @assistantTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get assistantTitle;

  /// No description provided for @assistantSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu agente de reposición'**
  String get assistantSubtitle;

  /// No description provided for @assistantGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola. Reviso tu stock, preparo pedidos a tus proveedores y los pago con PayPal, siempre dentro de tus reglas de gasto.'**
  String get assistantGreeting;

  /// No description provided for @assistantChipReview.
  ///
  /// In es, this message translates to:
  /// **'Revisa el stock ahora'**
  String get assistantChipReview;

  /// No description provided for @assistantChipPending.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tengo por aprobar?'**
  String get assistantChipPending;

  /// No description provided for @assistantChipSpent.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto llevo gastado?'**
  String get assistantChipSpent;

  /// No description provided for @assistantInputHint.
  ///
  /// In es, this message translates to:
  /// **'Pregunta lo que quieras'**
  String get assistantInputHint;

  /// No description provided for @assistantTyping.
  ///
  /// In es, this message translates to:
  /// **'Revisando tu stock…'**
  String get assistantTyping;

  /// No description provided for @assistantSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get assistantSend;

  /// No description provided for @assistantPendingEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes pedidos esperando tu aprobación.'**
  String get assistantPendingEmpty;

  /// No description provided for @assistantPendingList.
  ///
  /// In es, this message translates to:
  /// **'Tienes {count} por aprobar: {list}. Los encuentras en Inicio.'**
  String assistantPendingList(int count, String list);

  /// No description provided for @assistantPendingQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tengo por aprobar?'**
  String get assistantPendingQuestion;

  /// No description provided for @assistantSpentQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto llevo gastado?'**
  String get assistantSpentQuestion;

  /// No description provided for @assistantSpentAnswer.
  ///
  /// In es, this message translates to:
  /// **'Llevas **{spent}** gastados en {month} de un tope de **{limit}**. Te quedan **{remaining}**.'**
  String assistantSpentAnswer(
    String spent,
    String month,
    String limit,
    String remaining,
  );

  /// No description provided for @rulesTitle.
  ///
  /// In es, this message translates to:
  /// **'Reglas'**
  String get rulesTitle;

  /// No description provided for @rulesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'El agente solo paga si se cumplen todas'**
  String get rulesSubtitle;

  /// No description provided for @rulesSpending.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get rulesSpending;

  /// No description provided for @rulesAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get rulesAccount;

  /// No description provided for @rulesMonthlyLimit.
  ///
  /// In es, this message translates to:
  /// **'Tope mensual'**
  String get rulesMonthlyLimit;

  /// No description provided for @rulesMonthlyLimitText.
  ///
  /// In es, this message translates to:
  /// **'No gastes más de {amount} al mes'**
  String rulesMonthlyLimitText(String amount);

  /// No description provided for @rulesMonthlySpent.
  ///
  /// In es, this message translates to:
  /// **'Llevas {amount}'**
  String rulesMonthlySpent(String amount);

  /// No description provided for @rulesMaxPerOrder.
  ///
  /// In es, this message translates to:
  /// **'Máximo por pedido'**
  String get rulesMaxPerOrder;

  /// No description provided for @rulesMaxPerOrderText.
  ///
  /// In es, this message translates to:
  /// **'Ningún pedido puede pasar de {amount}'**
  String rulesMaxPerOrderText(String amount);

  /// No description provided for @rulesApproval.
  ///
  /// In es, this message translates to:
  /// **'Pide aprobación'**
  String get rulesApproval;

  /// No description provided for @rulesApprovalTextAny.
  ///
  /// In es, this message translates to:
  /// **'Pregúntame por cualquier pedido'**
  String get rulesApprovalTextAny;

  /// No description provided for @rulesApprovalTextAbove.
  ///
  /// In es, this message translates to:
  /// **'Si un pedido pasa de {amount}, pregúntame'**
  String rulesApprovalTextAbove(String amount);

  /// No description provided for @rulesSuppliers.
  ///
  /// In es, this message translates to:
  /// **'Proveedores'**
  String get rulesSuppliers;

  /// No description provided for @rulesSuppliersTextAny.
  ///
  /// In es, this message translates to:
  /// **'Puedes comprar a cualquier proveedor'**
  String get rulesSuppliersTextAny;

  /// No description provided for @rulesSuppliersTextList.
  ///
  /// In es, this message translates to:
  /// **'Compra solo a {list}'**
  String rulesSuppliersTextList(String list);

  /// No description provided for @rulesHint.
  ///
  /// In es, this message translates to:
  /// **'Toca una regla para cambiarla. Las reglas se comprueban en el sistema, no en la IA.'**
  String get rulesHint;

  /// No description provided for @rulesSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión'**
  String get rulesSession;

  /// No description provided for @rulesAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get rulesAppearance;

  /// No description provided for @rulesThemeAuto.
  ///
  /// In es, this message translates to:
  /// **'Auto'**
  String get rulesThemeAuto;

  /// No description provided for @rulesThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get rulesThemeLight;

  /// No description provided for @rulesThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get rulesThemeDark;

  /// No description provided for @rulesLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get rulesLanguage;

  /// No description provided for @rulesLanguageAuto.
  ///
  /// In es, this message translates to:
  /// **'Auto'**
  String get rulesLanguageAuto;

  /// No description provided for @rulesLanguageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get rulesLanguageSpanish;

  /// No description provided for @rulesLanguageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get rulesLanguageEnglish;

  /// No description provided for @rulesSounds.
  ///
  /// In es, this message translates to:
  /// **'Sonidos'**
  String get rulesSounds;

  /// No description provided for @rulesSignOutQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get rulesSignOutQuestion;

  /// No description provided for @rulesSignOutCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get rulesSignOutCancel;

  /// No description provided for @rulesSignOutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get rulesSignOutConfirm;

  /// No description provided for @rulesSaved.
  ///
  /// In es, this message translates to:
  /// **'Reglas guardadas'**
  String get rulesSaved;

  /// No description provided for @rulesSavedMessage.
  ///
  /// In es, this message translates to:
  /// **'Tus límites de gasto y proveedores ya están aplicados.'**
  String get rulesSavedMessage;

  /// No description provided for @rulesSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar las reglas'**
  String get rulesSaveFailed;

  /// No description provided for @rulesMonthlyLimitSheetHint.
  ///
  /// In es, this message translates to:
  /// **'No puede ser menor que el máximo por pedido.'**
  String get rulesMonthlyLimitSheetHint;

  /// No description provided for @rulesMaxPerOrderSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Tiene que ser mayor que 0.'**
  String get rulesMaxPerOrderSheetHint;

  /// No description provided for @rulesApprovalSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedir aprobación a partir de'**
  String get rulesApprovalSheetTitle;

  /// No description provided for @rulesApprovalSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Con 0 me preguntas por cualquier pedido.'**
  String get rulesApprovalSheetHint;

  /// No description provided for @rulesSuppliersSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Proveedores permitidos'**
  String get rulesSuppliersSheetTitle;

  /// No description provided for @rulesSuppliersSheetHint.
  ///
  /// In es, this message translates to:
  /// **'Si no marcas ninguno, el agente puede comprar a todos.'**
  String get rulesSuppliersSheetHint;

  /// No description provided for @authEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get authConfirmPassword;

  /// No description provided for @authStoreName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de tu tienda'**
  String get authStoreName;

  /// No description provided for @authStoreNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tienda Lumbre'**
  String get authStoreNameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@tienda.com'**
  String get authEmailHint;

  /// No description provided for @authSignInFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión'**
  String get authSignInFailed;

  /// No description provided for @authMissingFields.
  ///
  /// In es, this message translates to:
  /// **'Faltan datos'**
  String get authMissingFields;

  /// No description provided for @authMissingFieldsBody.
  ///
  /// In es, this message translates to:
  /// **'Completa el correo y la contraseña.'**
  String get authMissingFieldsBody;

  /// No description provided for @authMissingEmail.
  ///
  /// In es, this message translates to:
  /// **'Falta el correo'**
  String get authMissingEmail;

  /// No description provided for @authMissingEmailBody.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo primero.'**
  String get authMissingEmailBody;

  /// No description provided for @authEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Correo enviado'**
  String get authEmailSent;

  /// No description provided for @authEmailSentBody.
  ///
  /// In es, this message translates to:
  /// **'Si el correo existe, te enviamos un enlace de recuperación.'**
  String get authEmailSentBody;

  /// No description provided for @authFirstTime.
  ///
  /// In es, this message translates to:
  /// **'¿Primera vez en Restock?'**
  String get authFirstTime;

  /// No description provided for @authFirstTimeBody.
  ///
  /// In es, this message translates to:
  /// **'Crea tu tienda y deja que el agente reponga el stock.'**
  String get authFirstTimeBody;

  /// No description provided for @authCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authCreateTitle;

  /// No description provided for @authCreateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu tienda y empieza a reponer en segundos'**
  String get authCreateSubtitle;

  /// No description provided for @authCreateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la cuenta'**
  String get authCreateFailed;

  /// No description provided for @authCreateMissingFieldsBody.
  ///
  /// In es, this message translates to:
  /// **'Completa el correo y las dos contraseñas.'**
  String get authCreateMissingFieldsBody;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordTooShortTitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña corta'**
  String get authPasswordTooShortTitle;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get authPasswordsMismatch;

  /// No description provided for @authPasswordsMismatchTitle.
  ///
  /// In es, this message translates to:
  /// **'No coinciden'**
  String get authPasswordsMismatchTitle;

  /// No description provided for @authCreateFooter.
  ///
  /// In es, this message translates to:
  /// **'Crear la tienda es gratis. Solo pagas los pedidos que el agente prepare y tú apruebes, dentro de tus reglas.'**
  String get authCreateFooter;

  /// No description provided for @errorLoadData.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus datos'**
  String get errorLoadData;

  /// No description provided for @errorAgentBusy.
  ///
  /// In es, this message translates to:
  /// **'El agente ya está trabajando.'**
  String get errorAgentBusy;

  /// No description provided for @decisionOrderCreated.
  ///
  /// In es, this message translates to:
  /// **'Preparé un pedido de reposición con tu stock bajo.'**
  String get decisionOrderCreated;

  /// No description provided for @decisionNoAction.
  ///
  /// In es, this message translates to:
  /// **'Revisé el stock: no hacía falta pedir nada.'**
  String get decisionNoAction;

  /// No description provided for @decisionBlocked.
  ///
  /// In es, this message translates to:
  /// **'Quise pedir, pero tus reglas de gasto lo bloquearon.'**
  String get decisionBlocked;

  /// No description provided for @decisionFailed.
  ///
  /// In es, this message translates to:
  /// **'La revisión falló. Inténtalo de nuevo en un momento.'**
  String get decisionFailed;

  /// No description provided for @decisionAutoApproved.
  ///
  /// In es, this message translates to:
  /// **'Hice un pedido dentro de tus reglas y lo pagué con PayPal.'**
  String get decisionAutoApproved;

  /// No description provided for @decisionRequiresApproval.
  ///
  /// In es, this message translates to:
  /// **'Preparé un pedido que necesita tu aprobación.'**
  String get decisionRequiresApproval;

  /// No description provided for @decisionGeneric.
  ///
  /// In es, this message translates to:
  /// **'Revisión del agente: {decision}'**
  String decisionGeneric(String decision);

  /// No description provided for @agentChatFallback.
  ///
  /// In es, this message translates to:
  /// **'De momento sé revisar tu stock, proponer pedidos y pagarlos con PayPal dentro de tus reglas. Pulsa «Revisa el stock ahora» y me pongo con ello.'**
  String get agentChatFallback;

  /// No description provided for @agentChatTrigger.
  ///
  /// In es, this message translates to:
  /// **'Revisa el stock ahora'**
  String get agentChatTrigger;

  /// No description provided for @dateToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy {time}'**
  String dateToday(String time);

  /// No description provided for @dateYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer {time}'**
  String dateYesterday(String time);

  /// No description provided for @dashboardSignedIn.
  ///
  /// In es, this message translates to:
  /// **'Sesión iniciada'**
  String get dashboardSignedIn;

  /// No description provided for @dashboardUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get dashboardUser;

  /// No description provided for @dashboardStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda: {store}'**
  String dashboardStore(String store);

  /// No description provided for @dashboardNextStep.
  ///
  /// In es, this message translates to:
  /// **'Siguiente paso: catálogo, pedidos y agente.'**
  String get dashboardNextStep;

  /// No description provided for @errorAuthUserMissing.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener el usuario'**
  String get errorAuthUserMissing;

  /// No description provided for @errorAuthSignInFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión'**
  String get errorAuthSignInFailed;

  /// No description provided for @errorAuthSignUpFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar'**
  String get errorAuthSignUpFailed;

  /// No description provided for @errorAuthConfirmEmail.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada. Revisa tu correo para confirmarla e inicia sesión.'**
  String get errorAuthConfirmEmail;

  /// No description provided for @errorAuthSignOutFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cerrar sesión. Inténtalo de nuevo.'**
  String get errorAuthSignOutFailed;

  /// No description provided for @errorAuthResetEmailFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el correo de recuperación.'**
  String get errorAuthResetEmailFailed;

  /// No description provided for @errorAuthInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get errorAuthInvalidCredentials;

  /// No description provided for @errorAuthEmailTaken.
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya está registrado'**
  String get errorAuthEmailTaken;

  /// No description provided for @errorAuthWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get errorAuthWeakPassword;

  /// No description provided for @errorAuthEmailNotConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu correo antes de entrar'**
  String get errorAuthEmailNotConfirmed;

  /// No description provided for @errorAuthTooManyAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera un momento.'**
  String get errorAuthTooManyAttempts;

  /// No description provided for @errorAuthValidationFailed.
  ///
  /// In es, this message translates to:
  /// **'Revisa el correo y la contraseña'**
  String get errorAuthValidationFailed;

  /// No description provided for @errorSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Sesión caducada. Vuelve a iniciar sesión.'**
  String get errorSessionExpired;

  /// No description provided for @errorStoreLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la tienda'**
  String get errorStoreLoadFailed;

  /// No description provided for @errorStoreUpdateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar la tienda'**
  String get errorStoreUpdateFailed;

  /// No description provided for @errorStoreNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la tienda del usuario.'**
  String get errorStoreNotFound;

  /// No description provided for @errorStoreNameEmpty.
  ///
  /// In es, this message translates to:
  /// **'El nombre de la tienda no puede estar vacío.'**
  String get errorStoreNameEmpty;

  /// No description provided for @errorRulesNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron las reglas de gasto.'**
  String get errorRulesNotFound;

  /// No description provided for @errorRulesLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las reglas de gasto'**
  String get errorRulesLoadFailed;

  /// No description provided for @errorRulesSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron guardar las reglas de gasto'**
  String get errorRulesSaveFailed;

  /// No description provided for @errorRuleMaxPerOrderInvalid.
  ///
  /// In es, this message translates to:
  /// **'El máximo por pedido debe ser mayor que 0.'**
  String get errorRuleMaxPerOrderInvalid;

  /// No description provided for @errorRuleMonthlyBelowMax.
  ///
  /// In es, this message translates to:
  /// **'El límite mensual no puede ser menor que el máximo por pedido.'**
  String get errorRuleMonthlyBelowMax;

  /// No description provided for @errorRuleApprovalAboveMax.
  ///
  /// In es, this message translates to:
  /// **'El umbral de aprobación no puede superar el máximo por pedido.'**
  String get errorRuleApprovalAboveMax;

  /// No description provided for @errorOrdersLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los pedidos'**
  String get errorOrdersLoadFailed;

  /// No description provided for @errorOrderLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el pedido'**
  String get errorOrderLoadFailed;

  /// No description provided for @errorOrderCreateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear el pedido'**
  String get errorOrderCreateFailed;

  /// No description provided for @errorOrderSpentFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo calcular el gasto mensual'**
  String get errorOrderSpentFailed;

  /// No description provided for @errorOrderApproveFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo aprobar el pedido'**
  String get errorOrderApproveFailed;

  /// No description provided for @errorOrderRejectFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo rechazar el pedido'**
  String get errorOrderRejectFailed;

  /// No description provided for @errorOrderMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta el pedido.'**
  String get errorOrderMissing;

  /// No description provided for @errorOrderNotFound.
  ///
  /// In es, this message translates to:
  /// **'Ese pedido ya no existe.'**
  String get errorOrderNotFound;

  /// No description provided for @errorOrderEmpty.
  ///
  /// In es, this message translates to:
  /// **'El pedido no tiene líneas.'**
  String get errorOrderEmpty;

  /// No description provided for @errorOrderBlocked.
  ///
  /// In es, this message translates to:
  /// **'El pedido está bloqueado por tus reglas.'**
  String get errorOrderBlocked;

  /// No description provided for @errorOrderItemInvalidQty.
  ///
  /// In es, this message translates to:
  /// **'Cantidad no válida para {uid}.'**
  String errorOrderItemInvalidQty(String uid);

  /// No description provided for @errorOrderProductMissing.
  ///
  /// In es, this message translates to:
  /// **'No encuentro el producto {uid} en el catálogo.'**
  String errorOrderProductMissing(String uid);

  /// No description provided for @errorOrderProductInactive.
  ///
  /// In es, this message translates to:
  /// **'El producto {name} ya no está activo.'**
  String errorOrderProductInactive(String name);

  /// No description provided for @errorInvoiceLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la factura'**
  String get errorInvoiceLoadFailed;

  /// No description provided for @errorSuppliersLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los proveedores'**
  String get errorSuppliersLoadFailed;

  /// No description provided for @errorSupplierLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el proveedor'**
  String get errorSupplierLoadFailed;

  /// No description provided for @errorCatalogLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo'**
  String get errorCatalogLoadFailed;

  /// No description provided for @errorProductSearchFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar el producto'**
  String get errorProductSearchFailed;

  /// No description provided for @errorProductsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los productos'**
  String get errorProductsLoadFailed;

  /// No description provided for @errorLowStockLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el stock bajo'**
  String get errorLowStockLoadFailed;

  /// No description provided for @errorStockUpdateFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el stock'**
  String get errorStockUpdateFailed;

  /// No description provided for @errorProductMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta el producto.'**
  String get errorProductMissing;

  /// No description provided for @errorProductNotFound.
  ///
  /// In es, this message translates to:
  /// **'No existe ningún producto con UID {uid}.'**
  String errorProductNotFound(String uid);

  /// No description provided for @errorProductUidMissing.
  ///
  /// In es, this message translates to:
  /// **'Introduce un UID.'**
  String get errorProductUidMissing;

  /// No description provided for @errorStockNegative.
  ///
  /// In es, this message translates to:
  /// **'El stock no puede ser negativo.'**
  String get errorStockNegative;

  /// No description provided for @errorAgentUnreachable.
  ///
  /// In es, this message translates to:
  /// **'El agente no respondió'**
  String get errorAgentUnreachable;

  /// No description provided for @errorAgentFailed.
  ///
  /// In es, this message translates to:
  /// **'Error del agente'**
  String get errorAgentFailed;

  /// No description provided for @errorAgentRunsLoadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las ejecuciones'**
  String get errorAgentRunsLoadFailed;

  /// No description provided for @errorAgentStoreMissing.
  ///
  /// In es, this message translates to:
  /// **'Falta la tienda.'**
  String get errorAgentStoreMissing;

  /// No description provided for @errorPreviewNoSignOut.
  ///
  /// In es, this message translates to:
  /// **'En la vista previa no se cierra sesión.'**
  String get errorPreviewNoSignOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
