import '../../reader.dart';

part 'coverage.dart';
part 'lookup.dart';
part 'extension_subst.dart';
part 'ligature.dart';

class LigatureEntry {
  LigatureEntry(this.text, this.glyphId);

  final String text;
  final int glyphId;

  @override
  String toString() => 'LigatureEntry($text -> #$glyphId)';
}

/// Parses LookupType 4 (Ligature Substitution) entries from the GSUB table.
class GsubTable {
  static List<LigatureEntry> extractLigatures(
    BinaryReader r,
    Map<int, List<int>> glyphToCodepoints,
  ) {
    r.cursor = 0;
    final majorVersion = r.readUint16();
    final minorVersion = r.readUint16();
    r.skip(2); // scriptListOffset
    r.skip(2); // featureListOffset
    final lookupListOffset = r.readUint16();
    if (majorVersion == 1 && minorVersion >= 1) {
      r.skip(4); // featureVariationsOffset
    }

    final lookupListReader = r.sub(lookupListOffset);
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
