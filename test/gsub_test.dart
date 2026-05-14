import 'package:test/test.dart';
import 'package:icon_font_extractor/src/font/reader.dart';
import 'package:icon_font_extractor/src/font/tables/gsub/gsub.dart';

import 'support/byte_writer.dart';

void main() {
  group('GsubTable.extractLigatures', () {
    test('parses a single LookupType 4 ligature subtable', () {
      // Glyph 2 = 'h', glyph 3 = 'o', glyph 100 is the substituted ligature.
      final gsub = _buildGsub(
        wrapInExtension: false,
        ligatureGlyph: 100,
        firstComponentGlyph: 2,
        otherComponentGlyphs: const [3],
      );
      final cmapInverse = {
        2: [0x68],
        3: [0x6F],
      };

      final ligatures = GsubTable.extractLigatures(
        BinaryReader(gsub.toByteData()),
        cmapInverse,
      );

      expect(ligatures, hasLength(1));
      expect(ligatures.single.text, 'ho');
      expect(ligatures.single.glyphId, 100);
    });

    test(
      'unwraps LookupType 7 (Extension) wrapping a LookupType 4 subtable',
      () {
        final gsub = _buildGsub(
          wrapInExtension: true,
          ligatureGlyph: 200,
          firstComponentGlyph: 4,
          otherComponentGlyphs: const [5, 6],
        );
        final cmapInverse = {
          4: [0x61],
          5: [0x62],
          6: [0x63],
        };

        final ligatures = GsubTable.extractLigatures(
          BinaryReader(gsub.toByteData()),
          cmapInverse,
        );

        expect(ligatures, hasLength(1));
        expect(ligatures.single.text, 'abc');
        expect(ligatures.single.glyphId, 200);
      },
    );

    test('drops ligatures whose component glyphs have no codepoint', () {
      final gsub = _buildGsub(
        wrapInExtension: false,
        ligatureGlyph: 50,
        firstComponentGlyph: 9,
        otherComponentGlyphs: const [10],
      );
      // No cmap entry for glyph 10 — ligature should be skipped.
      final cmapInverse = {
        9: [0x68],
      };

      final ligatures = GsubTable.extractLigatures(
        BinaryReader(gsub.toByteData()),
        cmapInverse,
      );
      expect(ligatures, isEmpty);
    });

    test('prefers ASCII letter codepoints over arbitrary cmap entries', () {
      // Glyph 2 is mapped to both 0xE000 (PUA) and 0x68 ('h'); the ligature
      // text should use 'h', not the PUA codepoint.
      final gsub = _buildGsub(
        wrapInExtension: false,
        ligatureGlyph: 77,
        firstComponentGlyph: 2,
        otherComponentGlyphs: const [3],
      );
      final cmapInverse = {
        2: [0xE000, 0x68],
        3: [0xE001, 0x69],
      };

      final ligatures = GsubTable.extractLigatures(
        BinaryReader(gsub.toByteData()),
        cmapInverse,
      );

      expect(ligatures.single.text, 'hi');
    });
  });
}

/// Builds a minimal GSUB table containing a single LookupType 4 ligature.
///
/// When [wrapInExtension] is true, the ligature subtable is reached through a
/// LookupType 7 (Extension) indirection — exercising the Material Icons code
/// path.
ByteWriter _buildGsub({
  required bool wrapInExtension,
  required int ligatureGlyph,
  required int firstComponentGlyph,
  required List<int> otherComponentGlyphs,
}) {
  // --- LigatureSubst subtable -----------------------------------------------
  //
  // Layout (offsets within this subtable):
  //   0:  substFormat = 1
  //   2:  coverageOffset
  //   4:  ligatureSetCount = 1
  //   6:  ligatureSetOffsets[0]
  //   8:  Coverage format 1 (6 bytes: format, glyphCount, glyphArray[1])
  //   14: LigatureSet (ligatureCount=1, ligatureOffsets[0]=4)
  //   18: Ligature (ligatureGlyph, componentCount, components...)
  final componentCount = 1 + otherComponentGlyphs.length;
  final ligSubst = ByteWriter()
    ..u16(1) // substFormat
    ..u16(8) // coverageOffset
    ..u16(1) // ligatureSetCount
    ..u16(14) // ligatureSetOffsets[0]
    // Coverage format 1
    ..u16(1) // coverageFormat
    ..u16(1) // glyphCount
    ..u16(firstComponentGlyph)
    // LigatureSet
    ..u16(1) // ligatureCount
    ..u16(4) // ligatureOffsets[0] (relative to LigatureSet start)
    // Ligature
    ..u16(ligatureGlyph)
    ..u16(componentCount);
  for (final g in otherComponentGlyphs) {
    ligSubst.u16(g);
  }
  final ligSubstBytes = ligSubst.toBytes();

  // --- Wrap into Extension subtable if requested ----------------------------
  ByteWriter outerSubtable;
  int outerLookupType;
  if (wrapInExtension) {
    // Extension subtable layout:
    //   0: substFormat = 1
    //   2: extensionLookupType = 4
    //   4: extensionOffset (uint32, relative to start of extension subtable)
    //   8: ...inline LigatureSubst...
    outerLookupType = 7;
    outerSubtable = ByteWriter()
      ..u16(1) // substFormat
      ..u16(4) // extensionLookupType
      ..u32(8) // extensionOffset
      ..bytes(ligSubstBytes);
  } else {
    outerLookupType = 4;
    outerSubtable = ByteWriter()..bytes(ligSubstBytes);
  }
  final outerSubtableBytes = outerSubtable.toBytes();

  // --- Lookup table ---------------------------------------------------------
  // Layout:
  //   0: lookupType
  //   2: lookupFlag = 0
  //   4: subTableCount = 1
  //   6: subtableOffsets[0] = 8
  //   8: ...outer subtable...
  final lookup = ByteWriter()
    ..u16(outerLookupType)
    ..u16(0) // lookupFlag
    ..u16(1) // subTableCount
    ..u16(8) // subtableOffsets[0]
    ..bytes(outerSubtableBytes);

  // --- LookupList -----------------------------------------------------------
  // Layout:
  //   0: lookupCount = 1
  //   2: lookupOffsets[0] = 4
  //   4: ...lookup...
  final lookupList = ByteWriter()
    ..u16(1) // lookupCount
    ..u16(4) // lookupOffsets[0]
    ..bytes(lookup.toBytes());

  // --- GSUB header (10 bytes for v1.0) --------------------------------------
  return ByteWriter()
    ..u16(1) // majorVersion
    ..u16(0) // minorVersion
    ..u16(0) // scriptListOffset (unused by extractor)
    ..u16(0) // featureListOffset (unused)
    ..u16(10) // lookupListOffset
    ..bytes(lookupList.toBytes());
}
