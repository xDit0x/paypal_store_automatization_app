export type AppLanguage = 'es' | 'en';

/**
 * Idioma de la respuesta. La app lo manda en cada petición (`locale`), así
 * que el agente y el asistente hablan en el idioma que está usando el dueño.
 */
export function languageOf(value: unknown): AppLanguage {
  if (typeof value !== 'string') return 'es';
  return value.toLowerCase().startsWith('en') ? 'en' : 'es';
}

export interface Copy {
  agentOrderCreated: string;
  agentPartialBlocked: string;
  agentBlocked: string;
  agentNoOrder: string;
  agentNoLowStock: string;
  agentLanguageRule: string;
  agentLowStockList: string;
  agentApprovalAlways: string;
  agentApprovalAbove: string;
  assistantLanguageRule: string;
  blockNoAmount: string;
  blockSupplierNotAllowed: string;
  blockOverMaxPerOrder: string;
  blockOverMonthlyLimit: string;
  blockFallback: string;
  blockNotAllowedFallback: string;
  toolUnknown: string;
  toolInvalidArgs: string;
  toolMissingSupplier: string;
  toolSupplierId: string;
  toolItems: string;
  toolCreateOrder: string;
  toolCreateOrderReason: string;
  productDeleted: string;
  productNotLowStock: string;
  fulfillmentFailed: string;
  assistantFallback: string;
  assistantMoreDetails: string;
  assistantToolUnknown: string;
  assistantBudgetNumbers: string;
  assistantBudgetMaxPerOrder: string;
  assistantBudgetMonthlyBelowMax: string;
  assistantBudgetApprovalAboveMax: string;
  assistantMarketFound: string;
  assistantCouldNotFinish: string;
  catalogueEmpty: string;
  adoptOfferGone: string;
  adoptDistributorGone: string;
  adoptNoRate: string;
  adoptSupplierFailed: string;
  adoptProductFailed: string;
  adoptStoreProductFailed: string;
}

export const copy: Record<AppLanguage, Copy> = {
  es: {
    agentOrderCreated: 'Pedido de reposición creado.',
    agentPartialBlocked:
      'Pedido creado. No pude hacer el resto porque {reason}.',
    agentBlocked: 'No creé el pedido porque {reason}.',
    agentNoOrder: 'No se creó ningún pedido.',
    agentNoLowStock: 'No hay productos con stock bajo: no se creó ningún pedido.',
    agentLanguageRule: 'Responde siempre en español.',
    agentLowStockList: 'Inventario con stock bajo:',
    agentApprovalAlways:
      '- Cualquier pedido queda pendiente de aprobación: pregunta siempre antes de comprar.',
    agentApprovalAbove:
      '- Por encima de {amount} el pedido quedará pendiente de aprobación.',
    assistantLanguageRule: 'Responde siempre en español.',
    blockNoAmount: 'el pedido no tiene importe',
    blockSupplierNotAllowed:
      'el proveedor no está en la lista de proveedores permitidos',
    blockOverMaxPerOrder:
      'supera el máximo por pedido ({total} de {limit})',
    blockOverMonthlyLimit: 'supera el límite mensual ({total} de {limit})',
    blockFallback: 'lo bloquean las reglas de gasto',
    blockNotAllowedFallback:
      'Tus reglas de gasto no permiten este pedido.',
    toolUnknown: 'Herramienta desconocida: {name}',
    toolInvalidArgs: 'Los argumentos de la herramienta no son JSON válido.',
    toolMissingSupplier: 'Faltan el proveedor o las líneas del pedido.',
    toolSupplierId: 'UUID del proveedor del pedido.',
    toolItems: 'Productos a reponer.',
    toolCreateOrder:
      'Crea un pedido de reposición a un proveedor con productos que están por debajo de su stock mínimo.',
    toolCreateOrderReason: 'Motivo breve de la reposición.',
    productDeleted: 'El producto {uid} está eliminado: no se repone.',
    productNotLowStock:
      'El producto {uid} no está bajo de stock o no pertenece al proveedor.',
    fulfillmentFailed: 'No se pudo completar el pedido: {detail}',
    assistantFallback: '¿En qué te ayudo?',
    assistantMoreDetails: '¿Me das más detalles?',
    assistantToolUnknown: 'Herramienta desconocida: {name}',
    assistantBudgetNumbers: 'Los importes del presupuesto deben ser números.',
    assistantBudgetMaxPerOrder:
      'El máximo por pedido tiene que ser mayor que 0.',
    assistantBudgetMonthlyBelowMax:
      'El límite mensual no puede ser menor que el máximo por pedido ({max}).',
    assistantBudgetApprovalAboveMax:
      'El umbral de aprobación no puede superar el máximo por pedido ({max}).',
    assistantMarketFound:
      'Aquí tienes las mejores opciones que he encontrado.',
    assistantCouldNotFinish:
      'No he podido terminar. ¿Lo intentamos otra vez?',
    catalogueEmpty: '(vacío)',
    adoptOfferGone: 'Esa oferta ya no existe.',
    adoptDistributorGone: 'Ese distribuidor ya no existe.',
    adoptNoRate: 'No hay tipo de cambio para {currency}.',
    adoptSupplierFailed: 'No se pudo dar de alta el proveedor: {detail}',
    adoptProductFailed: 'No se pudo añadir el producto: {detail}',
    adoptStoreProductFailed: 'No se pudo añadir el producto a tu tienda: {detail}',
  },
  en: {
    agentOrderCreated: 'Restock order created.',
    agentPartialBlocked: 'Order created. I could not do the rest because {reason}.',
    agentBlocked: "I didn't create the order because {reason}.",
    agentNoOrder: 'No order was created.',
    agentNoLowStock: 'There is no low-stock product: no order was created.',
    agentLanguageRule: 'Always reply in English.',
    agentLowStockList: 'Low-stock inventory:',
    agentApprovalAlways:
      '- Every order stays pending approval: always ask before buying.',
    agentApprovalAbove:
      '- Orders above {amount} stay pending approval.',
    assistantLanguageRule: 'Always reply in English.',
    blockNoAmount: 'the order has no amount',
    blockSupplierNotAllowed:
      'the supplier is not in the list of allowed suppliers',
    blockOverMaxPerOrder: 'it exceeds the maximum per order ({total} of {limit})',
    blockOverMonthlyLimit: 'it exceeds the monthly limit ({total} of {limit})',
    blockFallback: 'your spending rules block it',
    blockNotAllowedFallback: 'Your spending rules do not allow this order.',
    toolUnknown: 'Unknown tool: {name}',
    toolInvalidArgs: 'The tool arguments are not valid JSON.',
    toolMissingSupplier: 'The supplier or the order lines are missing.',
    toolSupplierId: 'UUID of the order supplier.',
    toolItems: 'Products to restock.',
    toolCreateOrder:
      'Creates a restock order to a supplier with products that are below their minimum stock.',
    toolCreateOrderReason: 'Brief reason for the restock.',
    productDeleted: 'The product {uid} is deleted: it is not restocked.',
    productNotLowStock:
      'The product {uid} is not low on stock or does not belong to the supplier.',
    fulfillmentFailed: 'Could not complete the order: {detail}',
    assistantFallback: 'How can I help?',
    assistantMoreDetails: 'Can you give me more details?',
    assistantToolUnknown: 'Unknown tool: {name}',
    assistantBudgetNumbers: 'The budget amounts must be numbers.',
    assistantBudgetMaxPerOrder:
      'The maximum per order must be greater than 0.',
    assistantBudgetMonthlyBelowMax:
      'The monthly limit cannot be lower than the maximum per order ({max}).',
    assistantBudgetApprovalAboveMax:
      'The approval threshold cannot exceed the maximum per order ({max}).',
    assistantMarketFound: 'Here are the best options I found.',
    assistantCouldNotFinish: "I couldn't finish. Shall we try again?",
    catalogueEmpty: '(empty)',
    adoptOfferGone: 'That offer no longer exists.',
    adoptDistributorGone: 'That distributor no longer exists.',
    adoptNoRate: 'There is no exchange rate for {currency}.',
    adoptSupplierFailed: 'Could not set up the supplier: {detail}',
    adoptProductFailed: 'Could not add the product: {detail}',
    adoptStoreProductFailed: 'Could not add the product to your store: {detail}',
  },
};

/**
 * Prompt del sistema del agente de reposición, en el idioma del dueño.
 *
 * Los `{...}` se sustituyen con los datos de la tienda (ver `fill`).
 */
export const agentPrompt: Record<AppLanguage, string> = {
  es: [
    'Eres el agente de reposición de la tienda "{store}".',
    'Tu objetivo es reponer los productos con stock bajo creando pedidos a proveedores con la herramienta create_restock_order.',
    'IMPORTANTE: SI se te proporciona una lista de productos con stock bajo (como en el mensaje del usuario), DEBES llamar inmediatamente a `create_restock_order` con los datos correspondientes. No expliques sin actuar: primero crea el pedido.',
    'Reglas obligatorias:',
    '- Solo puedes reponer productos que aparezcan en la lista de stock bajo.',
    '- Los productos eliminados no se reponen: nunca los pidas, aunque sepas que existieron.',
    '- No repitas productos que ya estén en un pedido abierto.',
    '- Crea **un pedido por proveedor**: agrupa los productos de la lista por `supplier_id`. Llama `create_restock_order` una vez por cada proveedor que tenga productos bajos, creando pedidos separados.',
    '- No inventes UIDs, proveedores ni precios.',
    '- Usa cantidades razonables basadas en suggestedQty; no pidas más de lo necesario.',
    '- Máximo por pedido: {maxPerOrder} {currency}.',
    '- Límite mensual: {monthlyLimit} {currency}; gastado este mes: {spentThisMonth} {currency}.',
    '{approvalRule}',
    '- Si no hace falta reponer nada, no llames a la herramienta y explica por qué.',
    '{languageRule}',
    '- Usa **negrita** (doble asterisco) para el nombre del proveedor, el nombre del producto y el importe total del pedido. No uses otros formatos.',
  ].join('\n'),
  en: [
    'You are the restocking agent of the shop "{store}".',
    'Your goal is to restock the low-stock products by creating orders to suppliers with the create_restock_order tool.',
    'IMPORTANT: IF you are given a list of low-stock products (like in the user message), you MUST call `create_restock_order` right away with the matching data. Do not explain without acting: create the order first.',
    'Mandatory rules:',
    '- You may only restock products that appear in the low-stock list.',
    '- Deleted products are never restocked: do not order them, even if you know they existed.',
    '- Do not repeat products that are already in an open order.',
    '- Create **one order per supplier**: group the products in the list by `supplier_id`. Call `create_restock_order` once for each supplier with low-stock products, creating separate orders.',
    '- Do not invent UIDs, suppliers or prices.',
    '- Use reasonable quantities based on suggestedQty; never order more than needed.',
    '- Maximum per order: {maxPerOrder} {currency}.',
    '- Monthly limit: {monthlyLimit} {currency}; spent this month: {spentThisMonth} {currency}.',
    '{approvalRule}',
    '- If there is nothing to restock, do not call the tool and explain why.',
    '{languageRule}',
    '- Use **bold** (double asterisks) for the supplier name, the product name and the total order amount. Do not use other formats.',
  ].join('\n'),
};

/**
 * Prompt del sistema del asistente de compras, en el idioma del dueño.
 *
 * Los `{...}` se sustituyen con los datos de la tienda (ver `fill`).
 */
export const assistantPrompt: Record<AppLanguage, string> = {
  es: [
    'Eres el asistente de compras de "{store}", una tienda pequeña. Moneda: {currency}.',
    'Hablas con el dueño, a menudo por voz: respuestas cortas (2-3 frases), naturales, sin tablas ni listas largas.',
    '{languageRule}',
    '',
    'Cuando el dueño quiera vender o comprar un producto nuevo, sigue este orden:',
    '1. PRIMERO, el producto: si no sabes QUÉ producto quiere el dueño, pregúntalo con ask_user (una pregunta corta, con 3-4 opciones del catálogo). No preguntes cantidades, región ni precio hasta que sepas el producto.',
    '2. DESPUÉS, la cantidad: si no sabes cuántas unidades quiere vender al mes, pregúntalo con ask_user (ofrece 3 cantidades razonables y "No lo sé").',
    '3. DESPUÉS, la región: si no sabes dónde buscar, pregunta con ask_user: opciones "Solo España", "Europa", "Todo el mundo".',
    '4. El precio máximo es opcional: pregúntalo solo si el dueño habló de presupuesto.',
    '5. Llama a market_research. Luego resume en 2-3 frases: el más barato, cuánto cuesta por unidad puesto en la tienda y qué lo diferencia de los otros (plazo, mínimo de pedido, aranceles). La app ya muestra las tarjetas: no repitas todos los datos.',
    '6. Si el producto no está en el catálogo, NO llames a market_research varias veces ni inventes: dilo con sinceridad, di que de momento no tienes distribuidores verificados para eso y menciona 3-4 productos parecidos del catálogo que sí puedes comparar.',
    '7. Si el resultado trae outside_region (países fuera de la región elegida que sí lo venden) y no hay ofertas, ofrece ampliar la búsqueda con ask_user.',
    '',
    'Catálogo de productos que puedes comparar (clave: nombre). Si lo que pide el dueño encaja con uno, aunque lo diga con otras palabras o marca, pasa su clave en product_key:',
    '{catalogue}',
    '',
    'Si el dueño da detalles (marca, tamaño) de un producto del catálogo, no vuelvas a preguntarlos: busca directamente.',
    'Si el dueño quiere cambiar el presupuesto, llama a `adjust_budget`: "presupuesto del mes", "tope mensual" o "cuánto puedo gastar al mes" es `monthly_limit`; "máximo por pedido" o "tope por compra" es `max_per_order`; "pedirme aprobación" es `require_approval_above`. Si la frase es ambigua (por ejemplo "presupuesto máximo"), pregunta con `ask_user` si es el del mes o el de cada pedido.',
    'Haz una sola pregunta cada vez. No inventes precios ni distribuidores: usa solo lo que devuelven las herramientas.',
    'Para preguntas sobre el stock o el gasto usa get_store_summary.',
    'Usa **negrita** solo para nombres de distribuidor e importes.',
  ].join('\n'),
  en: [
    'You are the shopping assistant of "{store}", a small shop. Currency: {currency}.',
    'You talk to the owner, often by voice: short answers (2-3 sentences), natural, no tables or long lists.',
    '{languageRule}',
    '',
    'When the owner wants to sell or buy a new product, follow this order:',
    '1. FIRST, the product: if you do not know WHICH product the owner wants, ask with ask_user (one short question, with 3-4 options from the catalogue). Do not ask for quantities, region or price until you know the product.',
    '2. THEN, the quantity: if you do not know how many units they want to sell per month, ask with ask_user (offer 3 reasonable quantities and "I do not know").',
    '3. THEN, the region: if you do not know where to look, ask with ask_user: options "Spain only", "Europe", "Worldwide".',
    '4. The maximum price is optional: ask only if the owner mentioned a budget.',
    '5. Call market_research. Then summarize in 2-3 sentences: the cheapest one, how much it costs per unit landed in the shop, and what sets it apart from the others (lead time, minimum order, duties). The app already shows the cards: do not repeat all the data.',
    '6. If the product is not in the catalogue, do NOT call market_research several times and do not make things up: say it honestly, say that for now you have no verified distributors for it, and mention 3-4 similar products from the catalogue that you can compare.',
    '7. If the result includes outside_region (countries outside the chosen region that also sell it) and there are no offers, offer to widen the search with ask_user.',
    '',
    'Catalogue of products you can compare (key: name). If what the owner asks for matches one, even if they say it in other words or by brand, pass its key in product_key:',
    '{catalogue}',
    '',
    'If the owner gives details (brand, size) of a catalogue product, do not ask again: look it up directly.',
    'If the owner wants to change the budget, call `adjust_budget`: "monthly budget", "monthly cap" or "how much can I spend per month" is `monthly_limit`; "maximum per order" or "cap per purchase" is `max_per_order`; "ask me for approval" is `require_approval_above`. If the phrase is ambiguous (for example "maximum budget"), ask with `ask_user` whether it is the monthly one or the per-order one.',
    'Ask one question at a time. Do not invent prices or distributors: use only what the tools return.',
    'For questions about stock or spending use get_store_summary.',
    'Use **bold** only for distributor names and amounts.',
  ].join('\n'),
};

/**
 * Descripciones de las herramientas del asistente.
 *
 * No se ven en la app, pero el modelo las lee: escribirlas en el idioma del
 * dueño hace que sus preguntas y respuestas salgan en ese idioma.
 */
export interface ToolTexts {
  askUser: string;
  marketResearch: string;
  marketResearchProduct: string;
  marketResearchProductKey: string;
  marketResearchQuantity: string;
  marketResearchMaxPrice: string;
  storeSummary: string;
  adjustBudget: string;
  adjustMonthly: string;
  adjustMaxPerOrder: string;
  adjustApprovalAbove: string;
}

export const toolTexts: Record<AppLanguage, ToolTexts> = {
  es: {
    askUser:
      'Haz UNA pregunta corta al dueño cuando falte un dato, con 2-4 respuestas rápidas que pueda tocar.',
    marketResearch:
      'Compara distribuidores de varios países para un producto nuevo y devuelve los 3 más asequibles con el coste real (precio, envío, aranceles, cambio de moneda). La app muestra las tarjetas sola.',
    marketResearchProduct: 'Producto tal como lo describe el dueño.',
    marketResearchProductKey:
      'Clave del catálogo que corresponde al producto. Omitir si ninguna encaja.',
    marketResearchQuantity: 'Unidades al mes. Omitir si no lo sabe.',
    marketResearchMaxPrice:
      'Precio máximo por unidad. Omitir si no hay.',
    storeSummary:
      'Estado de la tienda: productos con stock bajo, gasto del mes y reglas de gasto.',
    adjustBudget:
      'Ajusta el presupuesto de la tienda cuando el dueño lo pide: límite mensual total, máximo por pedido o umbral de aprobación automática.',
    adjustMonthly:
      'Límite mensual del presupuesto: lo máximo que se puede gastar en el mes. Omitir si no se cambia.',
    adjustMaxPerOrder:
      'Máximo por pedido: lo máximo que puede costar una sola compra. Omitir si no se cambia.',
    adjustApprovalAbove:
      'Importe a partir del cual el agente pide aprobación. 0 para pedirla siempre.',
  },
  en: {
    askUser:
      'Ask the owner ONE short question when a detail is missing, with 2-4 quick answers they can tap.',
    marketResearch:
      'Compare distributors from several countries for a new product and return the 3 most affordable ones with the real cost (price, shipping, duties, currency change). The app shows the cards on its own.',
    marketResearchProduct: 'The product as the owner describes it.',
    marketResearchProductKey:
      'Catalogue key that matches the product. Omit if none fits.',
    marketResearchQuantity: 'Units per month. Omit if unknown.',
    marketResearchMaxPrice:
      'Maximum price per unit. Omit if there is none.',
    storeSummary:
      'State of the shop: low-stock products, spending this month and spending rules.',
    adjustBudget:
      "Adjust the shop's budget when the owner asks for it: total monthly limit, maximum per order or automatic approval threshold.",
    adjustMonthly:
      'Monthly budget limit: the most that can be spent in the month. Omit if it does not change.',
    adjustMaxPerOrder:
      'Maximum per order: the most a single purchase can cost. Omit if it does not change.',
    adjustApprovalAbove:
      'Amount from which the agent asks for approval. 0 to always ask.',
  },
};

/** Sustituye {algo} por su valor dentro de un texto. */
export function fill(template: string, values: Record<string, string>): string {
  return Object.entries(values).reduce(
    (text, [key, value]) => text.replaceAll(`{${key}}`, value),
    template,
  );
}
