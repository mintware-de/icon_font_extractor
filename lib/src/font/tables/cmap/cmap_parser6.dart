part of 'cmap.dart';

/// Format 6 — trimmed table mapping (dense range).
class _CmapFormat6 {
  static Map<int, int> parse(BinaryReader r) {
    r.skip(2); // length
    r.skip(2); // language
    final firstCode = r.readUint16();
    final entryCount = r.readUint16();
    final out = <int, int>{};
    for (var i = 0; i < entryCount; i++) {
      final gid = r.readUint16();
      if (gid != 0) out[firstCode + i] = gid;
    }
    return out;
  }
}
