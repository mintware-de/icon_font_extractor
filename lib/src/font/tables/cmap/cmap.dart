import '../../reader.dart';

part 'encoding_record.dart';

part 'cmap_parser0.dart';

part 'cmap_parser4.dart';

part 'cmap_parser6.dart';

part 'cmap_parser12.dart';

/// Parsed `cmap` table: codepoint -> glyph index.
class CmapTable {
  /// Constructor
  CmapTable(this.codepointToGlyph);

  /// The map between codepoints and glyphs
  final Map<int, int> codepointToGlyph;

  /// The reverse map between glyphs to code points
  Map<int, List<int>> get glyphToCodepoints {
    final out = <int, List<int>>{};
    codepointToGlyph.forEach((cp, gid) {
      (out[gid] ??= <int>[]).add(cp);
    });
    return out;
  }

  /// Picks the "best" codepoint for a glyph. Prefers Private Use Areas
  /// (typical of icon fonts).
  int? bestCodepointFor(int glyphId) {
    final cps = glyphToCodepoints[glyphId];
    if (cps == null || cps.isEmpty) return null;
    cps.sort((a, b) => _puaScore(b).compareTo(_puaScore(a)));
    return cps.first;
  }

  static int _puaScore(int cp) {
    if (cp >= 0xE000 && cp <= 0xF8FF) return 3;
    if (cp >= 0xF0000 && cp <= 0xFFFFD) return 2;
    if (cp >= 0x100000 && cp <= 0x10FFFD) return 2;
    return 1;
  }

  /// Reads the Cmap table from the [reader].
  static CmapTable parse(BinaryReader reader) {
    reader.cursor = 0;
    reader.skip(2); // version
    final numTables = reader.readUint16();

    final encodingRecords = <_EncodingRecord>[];
    for (var i = 0; i < numTables; i++) {
      encodingRecords.add(_EncodingRecord.read(reader));
    }
    encodingRecords.sort((a, b) => b.priority.compareTo(a.priority));

    final merged = <int, int>{};
    for (final rec in encodingRecords) {
      final sub = reader.sub(rec.offset);
      final format = sub.readUint16();
      final parsed = switch (format) {
        0 => _CmapFormat0.parse(sub),
        4 => _CmapFormat4.parse(sub),
        6 => _CmapFormat6.parse(sub),
        12 => _CmapFormat12.parse(sub),
        _ => null,
      };
      parsed?.forEach((cp, gid) => merged.putIfAbsent(cp, () => gid));
    }
    return CmapTable(merged);
  }
}
