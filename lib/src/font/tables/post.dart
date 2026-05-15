import '../reader.dart';

/// Parses the `post` table to recover glyph names. Only used as a diagnostic
/// fallback — not required for the main code path.
class PostTable {
  /// The map of the glyph names
  final Map<int, String> glyphNames;

  /// Constructor
  PostTable(this.glyphNames);

  /// Reads the post table from the [reader]
  factory PostTable.parse(BinaryReader reader, int numGlyphs) {
    reader.cursor = 0;
    final version = reader.readUint32();
    reader.skip(4 + 2 + 2 + 4 + 16);

    final names = <int, String>{};
    if (version == 0x00020000) {
      final count = reader.readUint16();
      final glyphIndices = List<int>.generate(
        count,
        (_) => reader.readUint16(),
      );
      final pascalStrings = _readPascalStrings(reader);
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
