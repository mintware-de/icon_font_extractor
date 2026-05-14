part of 'cmap.dart';

class _EncodingRecord {
  _EncodingRecord(this.platformId, this.encodingId, this.offset);

  final int platformId;
  final int encodingId;
  final int offset;

  static _EncodingRecord read(BinaryReader r) {
    final platformId = r.readUint16();
    final encodingId = r.readUint16();
    final offset = r.readUint32();
    return _EncodingRecord(platformId, encodingId, offset);
  }

  /// Higher score = parsed first; first writer wins in the merged map.
  int get priority {
    if (platformId == 3 && encodingId == 10) return 100; // Unicode full
    if (platformId == 0 && encodingId == 6) return 95; // Unicode full (BMP+)
    if (platformId == 0 && encodingId == 4) return 90; // Unicode full (BMP)
    if (platformId == 3 && encodingId == 1) return 80; // Windows BMP
    if (platformId == 0) return 70; // Unicode (other)
    return 10;
  }
}
