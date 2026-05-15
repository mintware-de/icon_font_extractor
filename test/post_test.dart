import 'package:test/test.dart';
import 'package:icon_font_extractor/src/font/reader.dart';
import 'package:icon_font_extractor/src/font/tables/post.dart';

import 'support/byte_writer.dart';

void main() {
  group('PostTable.parse', () {
    test('returns empty map for non-format-2 table (format 1)', () {
      final w = _postHeader(version: 0x00010000);
      final table = PostTable.parse(BinaryReader(w.toByteData()), 0);
      expect(table.glyphNames, isEmpty);
    });

    test('parses a format-2 table with named glyphs', () {
      // Glyph 0 → standard index 3 (i.e., no custom name, skipped)
      // Glyph 1 → custom name "home"   (index 258 + 0)
      // Glyph 2 → custom name "search" (index 258 + 1)
      final table = _buildFormat2({1: 'home', 2: 'search'}, numGlyphs: 3);
      expect(table.glyphNames[1], 'home');
      expect(table.glyphNames[2], 'search');
      // Glyph 0 uses a built-in Mac name index (<258), so it's not included.
      expect(table.glyphNames.containsKey(0), isFalse);
    });

    test('handles glyphs with longer names', () {
      final table = _buildFormat2({
        1: 'arrow_back_ios',
        2: 'check_circle_outline',
      }, numGlyphs: 3);
      expect(table.glyphNames[1], 'arrow_back_ios');
      expect(table.glyphNames[2], 'check_circle_outline');
    });

    test('skips glyphs whose index points outside the custom string pool', () {
      // Build manually: 2 glyphs, glyph 0 → built-in (index 3), glyph 1 → custom (index 258)
      // but supply 0 pascal strings so the pool is empty → glyph 1 is silently skipped.
      final w = _postHeader(version: 0x00020000)
        ..u16(2) // count
        ..u16(3) // glyph 0 → built-in
        ..u16(258); // glyph 1 → custom index 0, but no strings follow
      final table = PostTable.parse(BinaryReader(w.toByteData()), 0);
      expect(table.glyphNames, isEmpty);
    });

    test('handles empty glyph count', () {
      final w = _postHeader(version: 0x00020000)..u16(0);
      final table = PostTable.parse(BinaryReader(w.toByteData()), 0);
      expect(table.glyphNames, isEmpty);
    });
  });
}

/// Builds a `post` table with format 2, mapping [glyphIdToName].
/// [numGlyphs] is the total glyph count; glyphs not in the map get built-in
/// index 0 (i.e., mapped to standard Mac name at slot 0, not included in
/// custom output).
PostTable _buildFormat2(
  Map<int, String> glyphIdToName, {
  required int numGlyphs,
}) {
  // Collect custom strings in stable order.
  final sortedIds = glyphIdToName.keys.toList()..sort();
  final customNames = [for (final id in sortedIds) glyphIdToName[id]!];

  final w = _postHeader(version: 0x00020000);
  w.u16(numGlyphs); // numberOfGlyphs

  // glyph-index array: custom glyphs get 258+i, others get built-in 0.
  int customIdx = 0;
  for (var gid = 0; gid < numGlyphs; gid++) {
    if (glyphIdToName.containsKey(gid)) {
      w.u16(258 + customIdx);
      customIdx++;
    } else {
      w.u16(0); // maps to standard name ".notdef" (built-in index 0)
    }
  }

  // Pascal strings.
  for (final name in customNames) {
    final bytes = name.codeUnits;
    w.u8(bytes.length);
    w.bytes(bytes);
  }

  return PostTable.parse(BinaryReader(w.toByteData()), 0);
}

/// Writes the 32-byte `post` table header (version + fixed fields).
ByteWriter _postHeader({required int version}) {
  return ByteWriter()
    ..u32(version) // version
    ..u32(0) // italicAngle
    ..u16(0) // underlinePosition
    ..u16(0) // underlineThickness
    ..u32(0) // isFixedPitch
    ..u32(0) // minMemType42
    ..u32(0) // maxMemType42
    ..u32(0) // minMemType1
    ..u32(0); // maxMemType1
}
