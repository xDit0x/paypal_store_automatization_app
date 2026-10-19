import { env } from '../../config/env.js';

let cachedToken: { value: string; expiresAt: number } | null = null;

export function paypalConfigured(): boolean {
  return Boolean(env.paypalClientId && env.paypalClientSecret);
}

async function getAccessToken(): Promise<string> {
  if (!paypalConfigured()) {
    throw new Error('PayPal no está configurado.');
  }

  if (cachedToken && cachedToken.expiresAt > Date.now() + 30_000) {
    return cachedToken.value;
  }

  const credentials = Buffer.from(
    `${env.paypalClientId}:${env.paypalClientSecret}`,
  ).toString('base64');

  const response = await fetch(`${env.paypalBaseUrl}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  if (!response.ok) {
    throw new Error(`PayPal auth ${response.status}: ${await response.text()}`);
  }

  const body = (await response.json()) as {
    access_token: string;
    expires_in: number;
  };

  cachedToken = {
    value: body.access_token,
    expiresAt: Date.now() + body.expires_in * 1000,
  };

  return body.access_token;
}

export async function paypalRequest<T>(
  path: string,
  init: { method: string; body?: unknown; headers?: Record<string, string> },
): Promise<T> {
  const token = await getAccessToken();
  const response = await fetch(`${env.paypalBaseUrl}${path}`, {
    method: init.method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...init.headers,
    },
    body: init.body === undefined ? undefined : JSON.stringify(init.body),
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`PayPal ${response.status}: ${text}`);
  }

  return (text ? JSON.parse(text) : {}) as T;
}
