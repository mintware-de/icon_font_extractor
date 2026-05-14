part of 'gsub.dart';

/// Reads a Lookup table entry and dispatches subtables to the right parser.
void _extractLookup(
  BinaryReader r,
  Map<int, List<int>> glyphToCodepoints,
  List<LigatureEntry> out,
) {
  final lookupType = r.readUint16();
  r.skip(2); // lookupFlag
  final subTableCount = r.readUint16();
  final subTableOffsets = List<int>.generate(
    subTableCount,
    (_) => r.readUint16(),
  );

  for (final subOffset in subTableOffsets) {
    switch (lookupType) {
      case 4:
        _Ligature._parseSubst(r.sub(subOffset), glyphToCodepoints, out);
      case 7:
        _unwrapExtensionSubst(r.sub(subOffset), glyphToCodepoints, out);
    }
  }
}
