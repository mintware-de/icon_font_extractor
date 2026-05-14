part of 'gsub.dart';

abstract final class _Ligature {
  /// Parses a single ligature record: a sequence of component glyphs → one result glyph.
  static LigatureEntry? _parse(
    BinaryReader r,
    int firstChar,
    Map<int, List<int>> glyphToCodepoints,
  ) {
    final ligGlyph = r.readUint16();
    final componentCount = r.readUint16();
    final buffer = StringBuffer()..writeCharCode(firstChar);
    for (var c = 1; c < componentCount; c++) {
      final ch = _bestChar(r.readUint16(), glyphToCodepoints);
      if (ch == null) return null;
      buffer.writeCharCode(ch);
    }
    return LigatureEntry(buffer.toString(), ligGlyph);
  }

  /// Parses a set of ligatures that all share the same first glyph.
  static void _parseLigatureSet(
    BinaryReader r,
    int firstChar,
    Map<int, List<int>> glyphToCodepoints,
    List<LigatureEntry> out,
  ) {
    final ligatureCount = r.readUint16();
    final ligatureOffsets = List<int>.generate(
      ligatureCount,
      (_) => r.readUint16(),
    );

    for (final ligOffset in ligatureOffsets) {
      final entry = _parse(r.sub(ligOffset), firstChar, glyphToCodepoints);
      if (entry != null) out.add(entry);
    }
  }

  /// LookupType 4 — Ligature Substitution (format 1).
  ///
  /// Groups glyphs into sets by first-glyph coverage, then delegates each set
  /// to [_parseLigatureSet].
  static void _parseSubst(
    BinaryReader r,
    Map<int, List<int>> glyphToCodepoints,
    List<LigatureEntry> out,
  ) {
    final substFormat = r.readUint16();
    if (substFormat != 1) return;
    final coverageOffset = r.readUint16();
    final ligatureSetCount = r.readUint16();
    final ligatureSetOffsets = List<int>.generate(
      ligatureSetCount,
      (_) => r.readUint16(),
    );

    final firstGlyphs = _parseCoverage(r.sub(coverageOffset));
    for (var i = 0; i < ligatureSetCount && i < firstGlyphs.length; i++) {
      final firstChar = _bestChar(firstGlyphs[i], glyphToCodepoints);
      if (firstChar == null) continue;
      _parseLigatureSet(
        r.sub(ligatureSetOffsets[i]),
        firstChar,
        glyphToCodepoints,
        out,
      );
    }
  }

  /// Returns the best codepoint for a glyph — preferring ASCII letters, digits,
  /// underscores, and hyphens so ligature names are readable identifiers.
  static int? _bestChar(int glyphId, Map<int, List<int>> glyphToCodepoints) {
    final codepoints = glyphToCodepoints[glyphId];
    if (codepoints == null || codepoints.isEmpty) return null;
    return codepoints.firstWhere(
      _isAsciiLigatureChar,
      orElse: () => codepoints.first,
    );
  }

  static bool _isAsciiLigatureChar(int codepoint) =>
      (codepoint >= 0x30 && codepoint <= 0x39) || // 0–9
      (codepoint >= 0x41 && codepoint <= 0x5A) || // A–Z
      (codepoint >= 0x61 && codepoint <= 0x7A) || // a–z
      codepoint == 0x5F || // _
      codepoint == 0x2D; // -
}
