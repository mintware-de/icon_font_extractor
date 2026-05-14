part of 'cmap.dart';

/// Format 4 — segment mapping to delta values (BMP).
class _CmapFormat4 {
  static Map<int, int> parse(BinaryReader r) {
    r.skip(2); // length
    r.skip(2); // language
    final segCount = r.readUint16() ~/ 2;
    r.skip(6); // searchRange, entrySelector, rangeShift

    final endCode = List<int>.generate(segCount, (_) => r.readUint16());
    r.skip(2); // reservedPad
    final startCode = List<int>.generate(segCount, (_) => r.readUint16());
    final idDelta = List<int>.generate(segCount, (_) => r.readInt16());
    final idRangeOffsetBase = r.cursor;
    final idRangeOffset = List<int>.generate(segCount, (_) => r.readUint16());

    final out = <int, int>{};
    for (var seg = 0; seg < segCount; seg++) {
      final start = startCode[seg];
      final end = endCode[seg];
      if (start == 0xFFFF && end == 0xFFFF) continue;
      for (var c = start; c <= end; c++) {
        final gid = _resolveGlyph(
          r,
          c: c,
          start: start,
          seg: seg,
          idDelta: idDelta[seg],
          idRangeOffset: idRangeOffset[seg],
          idRangeOffsetBase: idRangeOffsetBase,
        );
        if (gid != 0) out[c] = gid;
      }
    }
    return out;
  }

  static int _resolveGlyph(
    BinaryReader r, {
    required int c,
    required int start,
    required int seg,
    required int idDelta,
    required int idRangeOffset,
    required int idRangeOffsetBase,
  }) {
    if (idRangeOffset == 0) {
      return (c + idDelta) & 0xFFFF;
    }
    // The spec stores glyphIdArray inline right after the idRangeOffset array.
    // The offset is relative to the position of the idRangeOffset[seg] field.
    final glyphIndexOffset =
        idRangeOffsetBase + seg * 2 + idRangeOffset + (c - start) * 2;
    if (glyphIndexOffset + 2 > r.length) return 0;
    final raw = r.sub(glyphIndexOffset, 2).readUint16();
    return raw == 0 ? 0 : (raw + idDelta) & 0xFFFF;
  }
}
