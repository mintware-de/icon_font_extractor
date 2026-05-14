import 'dart:typed_data';

/// Big-endian binary reader over a [ByteData] window.
class BinaryReader {
  BinaryReader(this._data, [this._offset = 0, int? length])
    : _length = length ?? (_data.lengthInBytes - _offset);

  final ByteData _data;
  final int _offset;
  final int _length;
  int _cursor = 0;

  int get cursor => _cursor;
  int get length => _length;
  int get remaining => _length - _cursor;

  set cursor(int value) {
    if (value < 0 || value > _length) {
      throw RangeError.range(value, 0, _length, 'cursor');
    }
    _cursor = value;
  }

  void skip(int n) => cursor = _cursor + n;

  int readUint8() {
    final v = _data.getUint8(_offset + _cursor);
    _cursor += 1;
    return v;
  }

  int readInt8() {
    final v = _data.getInt8(_offset + _cursor);
    _cursor += 1;
    return v;
  }

  int readUint16() {
    final v = _data.getUint16(_offset + _cursor);
    _cursor += 2;
    return v;
  }

  int readInt16() {
    final v = _data.getInt16(_offset + _cursor);
    _cursor += 2;
    return v;
  }

  int readUint24() {
    final hi = readUint8();
    final mid = readUint8();
    final lo = readUint8();
    return (hi << 16) | (mid << 8) | lo;
  }

  int readUint32() {
    final v = _data.getUint32(_offset + _cursor);
    _cursor += 4;
    return v;
  }

  int readInt32() {
    final v = _data.getInt32(_offset + _cursor);
    _cursor += 4;
    return v;
  }

  String readTag() {
    final bytes = <int>[readUint8(), readUint8(), readUint8(), readUint8()];
    return String.fromCharCodes(bytes);
  }

  /// Returns a child reader viewing `[start, start + length)` within this
  /// reader's window. The child has its own independent cursor.
  BinaryReader sub(int start, [int? length]) {
    final childLen = length ?? (_length - start);
    if (start < 0 || start + childLen > _length) {
      throw RangeError('sub($start, $childLen) outside [$_length]');
    }
    return BinaryReader(_data, _offset + start, childLen);
  }
}
