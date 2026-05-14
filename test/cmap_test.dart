import 'package:test/test.dart';
import 'package:icon_font_extractor/src/font/reader.dart';
import 'package:icon_font_extractor/src/font/tables/cmap/cmap.dart';

import 'support/byte_writer.dart';

void main() {
  group('CmapTable.parse', () {
    test('parses a format 4 subtable with one mapped segment', () {
      final cmap = _buildCmapWithFormat4(
        segments: const [
          _Seg4(startCode: 0x41, endCode: 0x42, idDelta: 10 - 0x41),
          _Seg4(startCode: 0xFFFF, endCode: 0xFFFF, idDelta: 1),
        ],
      );

      final parsed = CmapTable.parse(BinaryReader(cmap.toByteData()));
      // 'A' -> 10, 'B' -> 11; sentinel 0xFFFF must be skipped.
      expect(parsed.codepointToGlyph[0x41], 10);
      expect(parsed.codepointToGlyph[0x42], 11);
      expect(parsed.codepointToGlyph.containsKey(0xFFFF), isFalse);
    });

    test('parses a format 12 subtable', () {
      final cmap = _buildCmapWithFormat12(
        groups: const [
          _Group12(
            startCharCode: 0xE000,
            endCharCode: 0xE002,
            startGlyphID: 100,
          ),
        ],
      );
      final parsed = CmapTable.parse(BinaryReader(cmap.toByteData()));
      expect(parsed.codepointToGlyph[0xE000], 100);
      expect(parsed.codepointToGlyph[0xE001], 101);
      expect(parsed.codepointToGlyph[0xE002], 102);
    });
  });

  group('CmapTable.bestCodepointFor', () {
    test('prefers BMP Private Use Area codepoints over ASCII', () {
      final table = CmapTable({
        0x68: 5, // 'h'
        0xE900: 5, // PUA pointing to the same glyph
        0x12345: 5, // Supplementary PUA — same glyph
      });
      expect(table.bestCodepointFor(5), 0xE900);
    });

    test('returns null for glyphs without any cmap entry', () {
      final table = CmapTable({0x41: 1});
      expect(table.bestCodepointFor(99), isNull);
    });
  });

  test('glyphToCodepoints inverts the mapping deterministically', () {
    final table = CmapTable({0xE001: 7, 0xE002: 7, 0xE003: 8});
    final inverted = table.glyphToCodepoints;
    expect(inverted[7], unorderedEquals([0xE001, 0xE002]));
    expect(inverted[8], [0xE003]);
  });
}

class _Seg4 {
  const _Seg4({
    required this.startCode,
    required this.endCode,
    required this.idDelta,
  });
  final int startCode;
  final int endCode;
  final int idDelta;
}

class _Group12 {
  const _Group12({
    required this.startCharCode,
    required this.endCharCode,
    required this.startGlyphID,
  });
  final int startCharCode;
  final int endCharCode;
  final int startGlyphID;
}

/// Builds a complete cmap table containing a single (platform=3, encoding=1)
/// format-4 subtable.
ByteWriter _buildCmapWithFormat4({required List<_Seg4> segments}) {
  final subtable = ByteWriter();
  final segCount = segments.length;
  subtable
    ..u16(4) // format
    ..u16(0) // length placeholder (not validated by parser)
    ..u16(0) // language
    ..u16(segCount * 2)
    ..u16(0) // searchRange (unused)
    ..u16(0) // entrySelector
    ..u16(0); // rangeShift
  for (final s in segments) {
    subtable.u16(s.endCode);
  }
  subtable.u16(0); // reservedPad
  for (final s in segments) {
    subtable.u16(s.startCode);
  }
  for (final s in segments) {
    subtable.i16(s.idDelta);
  }
  for (var i = 0; i < segCount; i++) {
    subtable.u16(0); // idRangeOffset
  }

  final cmap = ByteWriter()
    ..u16(0) // version
    ..u16(1); // numTables
  const subtableOffset = 12; // header(4) + one encoding record(8)
  cmap
    ..u16(3) // platformId
    ..u16(1) // encodingId
    ..u32(subtableOffset)
    ..bytes(subtable.toBytes());
  return cmap;
}

/// Builds a complete cmap table containing a single format-12 subtable.
ByteWriter _buildCmapWithFormat12({required List<_Group12> groups}) {
  final subtable = ByteWriter()
    ..u16(12) // format
    ..u16(0) // reserved
    ..u32(0) // length (unused by parser)
    ..u32(0) // language
    ..u32(groups.length);
  for (final g in groups) {
    subtable
      ..u32(g.startCharCode)
      ..u32(g.endCharCode)
      ..u32(g.startGlyphID);
  }

  final cmap = ByteWriter()
    ..u16(0) // version
    ..u16(1) // numTables
    ..u16(3) // platformId
    ..u16(10) // encodingId
    ..u32(12) // subtableOffset
    ..bytes(subtable.toBytes());
  return cmap;
}
