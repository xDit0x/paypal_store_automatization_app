import type { AppLanguage } from './messages.js';

/**
 * Mensajes de error que el servidor devuelve a la app.
 *
 * La app los enseña tal cual, así que tienen que existir en los dos
 * idiomas: el servidor elige el idioma según el que le manda la app.
 */
export interface ErrorCopy {
  sessionInvalid: string;
  tooManyRequests: string;
  agentRateLimited: string;
  assistantRateLimited: string;
  assistantRetryLater: string;
  approvalsRateLimited: string;
  storeIdMissing: string;
  offerIdsMissing: string;
  messageMissing: string;
  assistantFailed: string;
  orderNotFound: string;
  orderState: string;
  orderAmountFailed: string;
  orderAmountMismatch: string;
  orderLoadFailed: string;
  paymentFailed: string;
  paypalLinkFailed: string;
  authConfirmFailed: string;
  captureFailed: string;
  refundFailed: string;
  rejectFailed: string;
  syncTokenInvalid: string;
  invalidJson: string;
  catalogErrors: string;
  stockNotInteger: string;
  thresholdNotInteger: string;
  productStateInvalid: string;
  productNotFound: string;
  storeCheckFailed: string;
  storeNotOwned: string;
  stockUpdateFailed: string;
  thresholdUpdateFailed: string;
  productStateFailed: string;
  stockChangesRateLimited: string;
  thresholdChangesRateLimited: string;
  catalogChangesRateLimited: string;
  reviewFailed: string;
}

export const errorCopy: Record<AppLanguage, ErrorCopy> = {
  es: {
    sessionInvalid: 'Sesión no válida.',
    tooManyRequests: 'Demasiadas peticiones. Espera un momento.',
    agentRateLimited:
      'Has pedido demasiadas revisiones seguidas. Espera un momento.',
    assistantRateLimited: 'Vas muy rápido. Espera un momento.',
    assistantRetryLater: 'Espera un momento antes de repetir.',
    approvalsRateLimited:
      'Demasiadas aprobaciones seguidas. Espera un momento.',
    storeIdMissing: 'Falta store_id.',
    offerIdsMissing: 'Faltan store_id u offer_id.',
    messageMissing: 'Falta el mensaje.',
    assistantFailed: 'El asistente no pudo responder.',
    orderNotFound: 'Pedido no encontrado.',
    orderState: 'El pedido está en estado "{status}".',
    orderAmountFailed: 'No se pudo calcular el importe del pedido.',
    orderAmountMismatch: 'El pedido no supera la comprobación de importe.',
    orderLoadFailed: 'No se pudo consultar el pedido.',
    paymentFailed: 'No se pudo completar el pago del pedido.',
    paypalLinkFailed: 'No se pudo obtener el enlace de PayPal.',
    authConfirmFailed: 'No se pudo confirmar la autorización.',
    captureFailed: 'No se pudo capturar el pago.',
    refundFailed: 'No se pudo reembolsar el pago.',
    rejectFailed: 'No se pudo rechazar el pedido.',
    syncTokenInvalid: 'Token de sincronización no válido o no configurado.',
    invalidJson: 'Payload JSON no válido.',
    catalogErrors: 'Errores al procesar el catálogo.',
    stockNotInteger:
      'El stock debe ser un número entero igual o mayor que 0.',
    thresholdNotInteger:
      'El mínimo debe ser un número entero igual o mayor que 0.',
    productStateInvalid: 'El estado del producto debe ser true o false.',
    productNotFound: 'Producto no encontrado.',
    storeCheckFailed: 'No se pudo comprobar la tienda.',
    storeNotOwned: 'La tienda no existe o no es tuya.',
    stockUpdateFailed: 'No se pudo actualizar el stock del producto.',
    thresholdUpdateFailed: 'No se pudo actualizar el mínimo del producto.',
    productStateFailed: 'No se pudo cambiar el estado del producto.',
    stockChangesRateLimited:
      'Demasiados cambios de stock. Espera un momento.',
    thresholdChangesRateLimited:
      'Demasiados cambios de mínimo. Espera un momento.',
    catalogChangesRateLimited:
      'Demasiados cambios de catálogo. Espera un momento.',
    reviewFailed: 'No se pudo completar la revisión de stock.',
  },
  en: {
    sessionInvalid: 'Invalid session.',
    tooManyRequests: 'Too many requests. Please wait a moment.',
    agentRateLimited:
      'You have requested too many reviews in a row. Please wait a moment.',
    assistantRateLimited: 'You are going too fast. Please wait a moment.',
    assistantRetryLater: 'Please wait a moment before repeating.',
    approvalsRateLimited: 'Too many approvals in a row. Please wait a moment.',
    storeIdMissing: 'store_id is missing.',
    offerIdsMissing: 'store_id and offer_id are missing.',
    messageMissing: 'The message is missing.',
    assistantFailed: 'The assistant could not reply.',
    orderNotFound: 'Order not found.',
    orderState: 'The order is in status "{status}".',
    orderAmountFailed: 'Could not calculate the order amount.',
    orderAmountMismatch: 'The order does not pass the amount check.',
    orderLoadFailed: 'Could not read the order.',
    paymentFailed: 'Could not complete the order payment.',
    paypalLinkFailed: 'Could not get the PayPal link.',
    authConfirmFailed: 'Could not confirm the authorization.',
    captureFailed: 'Could not capture the payment.',
    refundFailed: 'Could not refund the payment.',
    rejectFailed: 'Could not reject the order.',
    syncTokenInvalid: 'Invalid or missing sync token.',
    invalidJson: 'Invalid JSON payload.',
    catalogErrors: 'Errors while processing the catalogue.',
    stockNotInteger: 'Stock must be an integer equal to or greater than 0.',
    thresholdNotInteger:
      'The minimum must be an integer equal to or greater than 0.',
    productStateInvalid: 'The product state must be true or false.',
    productNotFound: 'Product not found.',
    storeCheckFailed: 'Could not check the shop.',
    storeNotOwned: 'The shop does not exist or is not yours.',
    stockUpdateFailed: 'Could not update the product stock.',
    thresholdUpdateFailed: 'Could not update the product minimum.',
    productStateFailed: 'Could not change the product state.',
    stockChangesRateLimited: 'Too many stock changes. Please wait a moment.',
    thresholdChangesRateLimited:
      'Too many minimum changes. Please wait a moment.',
    catalogChangesRateLimited:
      'Too many catalogue changes. Please wait a moment.',
    reviewFailed: 'Could not complete the stock review.',
  },
};
