import type { MarketRegion } from './market_math.js';

export interface WebResult {
  title: string;
  url: string;
  domain: string;
  snippet: string;
}

/**
 * Búsqueda real en internet con Tavily (plan gratuito). Opcional: sin
 * TAVILY_API_KEY no hace nada. Los resultados son "otros distribuidores
 * encontrados en la web": no traen precio fiable, así que no entran en la
 * comparación de costes.
 */
export async function searchDistributorsOnWeb(
  product: string,
  region: MarketRegion,
): Promise<WebResult[]> {
  const apiKey = process.env.TAVILY_API_KEY;
  if (!apiKey) return [];

  const query =
    region === 'spain'
      ? `${product} distribuidor mayorista para hostelería España`
      : region === 'europe'
        ? `${product} wholesale distributor for cafés Europe`
        : `${product} wholesale supplier for coffee shops`;

  try {
    const response = await fetch('https://api.tavily.com/search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        api_key: apiKey,
        query,
        max_results: 5,
        search_depth: 'basic',
        include_answer: false,
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) return [];

    const body = (await response.json()) as {
      results?: { title?: string; url?: string; content?: string }[];
    };

    return (body.results ?? [])
      .filter((r) => r.url && r.title)
      .slice(0, 5)
      .map((r) => {
        let domain = '';
        try {
          domain = new URL(r.url!).hostname.replace(/^www\./, '');
        } catch {
          domain = '';
        }
        return {
          title: r.title!.slice(0, 120),
          url: r.url!,
          domain,
          snippet: (r.content ?? '').replace(/\s+/g, ' ').slice(0, 220),
        };
      });
  } catch {
    return [];
  }
}
