import 'dart:typed_data';

/// Tiny helper for building big-endian byte sequences in tests.
class ByteWriter {
  final BytesBuilder _b = BytesBuilder();

  int get length => _b.length;

  void u8(int v) => _b.addByte(v & 0xFF);

  void u16(int v) {
    _b
      ..addByte((v >> 8) & 0xFF)
      ..addByte(v & 0xFF);
  }

  void i16(int v) {
    final u = v < 0 ? (v + 0x10000) : v;
    u16(u);
  }

  void u24(int v) {
    _b
      ..addByte((v >> 16) & 0xFF)
      ..addByte((v >> 8) & 0xFF)
      ..addByte(v & 0xFF);
  }

  void u32(int v) {
    _b
      ..addByte((v >> 24) & 0xFF)
      ..addByte((v >> 16) & 0xFF)
      ..addByte((v >> 8) & 0xFF)
      ..addByte(v & 0xFF);
  }

  void tag(String s) {
    if (s.length != 4) {
      throw ArgumentError('tag must be 4 chars, got "$s"');
    }
    for (final c in s.codeUnits) {
      _b.addByte(c & 0xFF);
    }
  }

  void bytes(List<int> data) {
    for (final v in data) {
      _b.addByte(v & 0xFF);
    }
  }

  /// Pads with zero bytes until [length] reaches [n].
  void padTo(int n) {
    while (_b.length < n) {
      _b.addByte(0);
    }
  }

  Uint8List toBytes() => _b.toBytes();

  ByteData toByteData() => ByteData.sublistView(toBytes());
}
