import '../../reader.dart';

part 'coverage.dart';

part 'lookup.dart';

part 'extension_subst.dart';

part 'ligature.dart';

/// Represents a single entry of a ligature
class LigatureEntry {
  /// The ligature text.
  final String text;

  /// The id of the glyph.
  final int glyphId;

  /// Constructor
  LigatureEntry(this.text, this.glyphId);

  @override
  String toString() => 'LigatureEntry($text -> #$glyphId)';
}

/// Parses LookupType 4 (Ligature Substitution) entries from the GSUB table.
class GsubTable {
  /// Reads the ligatures from the [reader].
  static List<LigatureEntry> extractLigatures(
    BinaryReader reader,
    Map<int, List<int>> glyphToCodepoints,
  ) {
    reader.cursor = 0;
    final majorVersion = reader.readUint16();
    final minorVersion = reader.readUint16();
    reader.skip(2); // scriptListOffset
    reader.skip(2); // featureListOffset
    final lookupListOffset = reader.readUint16();
    if (majorVersion == 1 && minorVersion >= 1) {
      reader.skip(4); // featureVariationsOffset
    }

    final lookupListReader = reader.sub(lookupListOffset);
    final lookupCount = lookupListReader.readUint16();
    final lookupOffsets = List<int>.generate(
      lookupCount,
      (_) => lookupListReader.readUint16(),
    );

    final result = <LigatureEntry>[];
    for (final lookupOffset in lookupOffsets) {
      _extractLookup(
        lookupListReader.sub(lookupOffset),
        glyphToCodepoints,
        result,
      );
    }
    return result;
  }
}
