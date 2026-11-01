import { env } from '../../config/env.js';

export interface EmailMessage {
  to: string[];
  subject: string;
  html: string;
  text: string;
  replyTo?: string;
}

export interface EmailResult {
  id: string;
}

export async function sendEmail(message: EmailMessage): Promise<EmailResult> {
  if (!env.resendApiKey) {
    throw new Error('Falta RESEND_API_KEY en el servidor.');
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${env.resendApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: env.emailFrom,
      to: message.to,
      subject: message.subject,
      html: message.html,
      text: message.text,
      ...(message.replyTo ? { reply_to: message.replyTo } : {}),
    }),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    throw new Error(`Resend respondió ${response.status}${detail ? `: ${detail}` : ''}`);
  }

  const data = (await response.json()) as { id?: string };
  return { id: data.id ?? '' };
}
