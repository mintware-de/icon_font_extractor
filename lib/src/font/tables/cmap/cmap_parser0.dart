part of 'cmap.dart';

/// Format 0 — byte encoding table (256-entry byte array).
class _CmapFormat0 {
  static Map<int, int> parse(BinaryReader r) {
    r.skip(2); // length
    r.skip(2); // language
    final out = <int, int>{};
    for (var i = 0; i < 256; i++) {
      final gid = r.readUint8();
      if (gid != 0) out[i] = gid;
    }
    return out;
  }
}
