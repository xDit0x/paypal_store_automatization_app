interface Bucket {
  count: number;
  resetAt: number;
}

/**
 * Limitador de peticiones en memoria (ventana fija). No hace falta una
 * dependencia: para el uso del backend (una instancia) es suficiente.
 */
export function createRateLimiter(options: { windowMs: number; max: number }) {
  const buckets = new Map<string, Bucket>();

  const sweep = setInterval(() => {
    const now = Date.now();
    for (const [key, bucket] of buckets) {
      if (bucket.resetAt <= now) buckets.delete(key);
    }
  }, options.windowMs);
  // No mantiene vivo el proceso solo por el temporizador.
  if (typeof sweep.unref === 'function') sweep.unref();

  return {
    check(key: string): { allowed: boolean; retryAfterSeconds: number } {
      const now = Date.now();
      const bucket = buckets.get(key);

      if (!bucket || bucket.resetAt <= now) {
        buckets.set(key, { count: 1, resetAt: now + options.windowMs });
        return { allowed: true, retryAfterSeconds: 0 };
      }

      if (bucket.count >= options.max) {
        return {
          allowed: false,
          retryAfterSeconds: Math.max(1, Math.ceil((bucket.resetAt - now) / 1000)),
        };
      }

      bucket.count += 1;
      return { allowed: true, retryAfterSeconds: 0 };
    },
  };
}
