part of 'gsub.dart';

/// LookupType 7 — Extension Substitution.
///
/// Each subtable holds a 32-bit offset to a real subtable of another lookup
/// type. Only wrapped LookupType 4 subtables are forwarded.
void _unwrapExtensionSubst(
  BinaryReader r,
  Map<int, List<int>> glyphToCodepoints,
  List<LigatureEntry> out,
) {
  final extFormat = r.readUint16();
  if (extFormat != 1) return;
  final extType = r.readUint16();
  final extInnerOffset = r.readUint32();
  if (extType != 4) return;
  _Ligature._parseSubst(r.sub(extInnerOffset), glyphToCodepoints, out);
}
