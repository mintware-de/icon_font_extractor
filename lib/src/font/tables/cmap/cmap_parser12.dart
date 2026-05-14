part of 'cmap.dart';

/// Format 12 — segmented coverage (full Unicode, including non-BMP).
class _CmapFormat12 {
  static Map<int, int> parse(BinaryReader r) {
    r.skip(2); // reserved
    r.skip(4); // length
    r.skip(4); // language
    final numGroups = r.readUint32();
    final out = <int, int>{};
    for (var i = 0; i < numGroups; i++) {
      final startCharCode = r.readUint32();
      final endCharCode = r.readUint32();
      final startGlyphId = r.readUint32();
      for (var c = startCharCode; c <= endCharCode; c++) {
        out[c] = startGlyphId + (c - startCharCode);
      }
    }
    return out;
  }
}
