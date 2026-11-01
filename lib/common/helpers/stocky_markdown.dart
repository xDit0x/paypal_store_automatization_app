/// Markdown sencillo que devuelve el agente: **negrita**, *cursiva* y
/// `código`. No hace falta una librería: se recorre el texto y se agrupan
/// los tramos en TextSpans. Los marcadores sin pareja se dejan tal cual.
library;

import 'package:flutter/material.dart';

enum _Mark { bold, italic, code, plain }

class _Chunk {
  const _Chunk(this.text, this.mark);

  final String text;
  final _Mark mark;
}

/// Trocea el texto en tramos con su tipo de marcado.
List<_Chunk> _chunkify(String text) {
  final chunks = <_Chunk>[];
  final buffer = StringBuffer();
  var i = 0;

  void flush() {
    if (buffer.isNotEmpty) {
      chunks.add(_Chunk(buffer.toString(), _Mark.plain));
      buffer.clear();
    }
  }

  while (i < text.length) {
    final char = text[i];

    if (char == '*' && i + 1 < text.length && text[i + 1] == '*') {
      final end = text.indexOf('**', i + 2);
      if (end != -1) {
        flush();
        chunks.add(_Chunk(text.substring(i + 2, end), _Mark.bold));
        i = end + 2;
        continue;
      }
      // Sin cierre: los dos asteriscos son texto normal.
      buffer.write('**');
      i += 2;
      continue;
    }

    if (char == '*') {
      final end = text.indexOf('*', i + 1);
      if (end != -1) {
        flush();
        chunks.add(_Chunk(text.substring(i + 1, end), _Mark.italic));
        i = end + 1;
        continue;
      }
      buffer.write(char);
      i++;
      continue;
    }

    if (char == '`') {
      final end = text.indexOf('`', i + 1);
      if (end != -1) {
        flush();
        chunks.add(_Chunk(text.substring(i + 1, end), _Mark.code));
        i = end + 1;
        continue;
      }
      buffer.write(char);
      i++;
      continue;
    }

    buffer.write(char);
    i++;
  }

  flush();
  return chunks;
}

/// Convierte el markdown en línea en una lista de spans con el estilo base.
List<TextSpan> buildInlineMarkdown(String text, TextStyle base) {
  return [
    for (final chunk in _chunkify(text))
      TextSpan(
        text: chunk.text,
        style: switch (chunk.mark) {
          _Mark.bold => base.copyWith(fontWeight: FontWeight.w700),
          _Mark.italic => base.copyWith(fontStyle: FontStyle.italic),
          _Mark.code => base.copyWith(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Menlo', 'Courier New'],
          ),
          _Mark.plain => base,
        },
      ),
  ];
}

/// Quita los marcadores de markdown y deja solo el texto.
String stripInlineMarkdown(String text) {
  return _chunkify(text).map((chunk) => chunk.text).join();
}
