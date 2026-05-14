part of 'gsub.dart';

/// Parses a Coverage table — lists the glyphs a substitution rule applies to.
///
/// Format 1: explicit list of glyph IDs.
/// Format 2: ranges of consecutive glyph IDs.
List<int> _parseCoverage(BinaryReader r) {
  final format = r.readUint16();
  final out = <int>[];
  switch (format) {
    case 1:
      final glyphCount = r.readUint16();
      for (var i = 0; i < glyphCount; i++) {
        out.add(r.readUint16());
      }
    case 2:
      final rangeCount = r.readUint16();
      for (var i = 0; i < rangeCount; i++) {
        final start = r.readUint16();
        final end = r.readUint16();
        r.skip(2); // startCoverageIndex
        for (var g = start; g <= end; g++) {
          out.add(g);
        }
      }
  }
  return out;
}
