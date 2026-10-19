import { paypalRequest } from './paypal_client.js';

export interface PayoutResult {
  batchId: string;
  status: string;
}

export async function sendPayout(params: {
  recipientEmail: string;
  amount: number;
  currency: string;
  note: string;
  senderBatchId: string;
}): Promise<PayoutResult> {
  const body = {
    sender_batch_header: {
      sender_batch_id: params.senderBatchId,
      email_subject: 'Restock — pago a proveedor',
      email_message: params.note,
    },
    items: [
      {
        recipient_type: 'EMAIL',
        amount: {
          currency: params.currency,
          value: params.amount.toFixed(2),
        },
        receiver: params.recipientEmail,
        note: params.note,
        sender_item_id: params.senderBatchId,
      },
    ],
  };

  const result = await paypalRequest<{
    batch_header: { payout_batch_id: string; batch_status: string };
  }>('/v1/payments/payouts', { method: 'POST', body });

  return {
    batchId: result.batch_header?.payout_batch_id ?? '',
    status: result.batch_header?.batch_status ?? 'PENDING',
  };
}
