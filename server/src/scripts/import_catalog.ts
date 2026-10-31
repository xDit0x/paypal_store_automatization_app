#!/usr/bin/env node
import { importCatalog } from '../application/catalog/import_catalog.js';

function parseArgs(args: string[]): { supplier?: string; file?: string; url?: string } {
  const result: { supplier?: string; file?: string; url?: string } = {};
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--supplier') result.supplier = args[++i];
    else if (arg === '--file') result.file = args[++i];
    else if (arg === '--url') result.url = args[++i];
  }
  return result;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.supplier) {
    console.error('Uso: tsx src/scripts/import_catalog.ts --supplier <id> --file <path> [--url <url>]');
    process.exit(1);
  }
  const content = args.file ? await readText(args.file) : args.url ? await fetchText(args.url) : '';
  if (!content) {
    console.error('No se pudo leer archivo ni URL');
    process.exit(1);
  }
  const result = await importCatalog({ storeId: args.supplier, type: 'json', content });
  console.log('Resultado:', JSON.stringify(result, null, 2));
}

async function readText(path: string): Promise<string> {
  try {
    const fs = await import('fs');
    return fs.readFileSync(path, 'utf-8');
  } catch {
    return '';
  }
}

async function fetchText(url: string): Promise<string> {
  try {
    const res = await fetch(url);
    return await res.text();
  } catch {
    return '';
  }
}

main().catch((err) => {
  console.error('Error importando catálogo:', err);
  process.exit(1);
});
