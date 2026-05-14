import '../reader.dart';

/// Parses the `post` table to recover glyph names. Only used as a diagnostic
/// fallback — not required for the main code path.
class PostTable {
  final Map<int, String> glyphNames;

  PostTable(this.glyphNames);

  factory PostTable.parse(BinaryReader r, int numGlyphs) {
    r.cursor = 0;
    final version = r.readUint32();
    r.skip(4 + 2 + 2 + 4 + 16);

    final names = <int, String>{};
    if (version == 0x00020000) {
      final count = r.readUint16();
      final glyphIndices = List<int>.generate(count, (_) => r.readUint16());
      final pascalStrings = _readPascalStrings(r);
      for (var gid = 0; gid < count; gid++) {
        final idx = glyphIndices[gid];
        if (idx >= 258) {
          final stringIdx = idx - 258;
          if (stringIdx < pascalStrings.length) {
            names[gid] = pascalStrings[stringIdx];
          }
        }
      }
    }
    return PostTable(names);
  }

  /// Reads the run of Pascal strings that follow the glyph-index array in a
  /// format-2 `post` table. Each string is length-prefixed (one byte).
  static List<String> _readPascalStrings(BinaryReader r) {
    final strings = <String>[];
    while (r.remaining > 0) {
      final len = r.readUint8();
      if (len == 0) {
        strings.add('');
        continue;
      }
      if (r.remaining < len) break;
      final bytes = List<int>.generate(len, (_) => r.readUint8());
      strings.add(String.fromCharCodes(bytes));
    }
    return strings;
  }
}
