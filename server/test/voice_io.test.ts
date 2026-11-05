import assert from 'node:assert/strict';
import test from 'node:test';

import { cleanTranscript, speakableText } from '../src/application/voice/voice_io.js';

test('descarta lo que Whisper "oye" en silencio', () => {
  assert.equal(cleanTranscript('Subtítulos realizados por la comunidad de Amara.org'), '');
  assert.equal(cleanTranscript(' ¡Gracias! '), '');
  assert.equal(cleanTranscript('.'), '');
  assert.equal(cleanTranscript('  Quiero  vender kombucha. '), 'Quiero vender kombucha.');
});

test('texto para leer en voz alta sin markdown', () => {
  assert.equal(
    speakableText('El más barato es **Horta Verda**: **1,45 €** por litro. [web](https://x.com)'),
    'El más barato es Horta Verda: 1,45 € por litro. web',
  );
});
