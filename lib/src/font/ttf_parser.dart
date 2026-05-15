import 'dart:typed_data';

import 'reader.dart';

class _TtfTable {
  _TtfTable(this.tag, this.offset, this.length);
  final String tag;
  final int offset;
  final int length;
}

/// Parses the sfnt header + table directory of a TTF/OTF font.
class TtfFont {
  TtfFont._(this._data, this._tables);

  final ByteData _data;
  final Map<String, _TtfTable> _tables;

  /// Parse
  static TtfFont parse(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final reader = BinaryReader(data);
    final scaler = reader.readUint32();
    const sfntVersionTrueType = 0x00010000;
    const sfntVersionOpenType = 0x4F54544F; // 'OTTO'
    const sfntVersionTrue = 0x74727565; // 'true'
    const sfntVersionTyp1 = 0x74797031; // 'typ1'
    if (scaler != sfntVersionTrueType &&
        scaler != sfntVersionOpenType &&
        scaler != sfntVersionTrue &&
        scaler != sfntVersionTyp1) {
      throw FormatException(
        'Not a single-font TTF/OTF (sfnt version 0x${scaler.toRadixString(16)})',
      );
    }
    final numTables = reader.readUint16();
    reader
      ..skip(2)
      ..skip(2)
      ..skip(2);

    final tables = <String, _TtfTable>{};
    for (var i = 0; i < numTables; i++) {
      final tag = reader.readTag();
      reader.skip(4); // checksum
      final offset = reader.readUint32();
      final length = reader.readUint32();
      tables[tag] = _TtfTable(tag, offset, length);
    }
    return TtfFont._(data, tables);
  }

  /// Checks if there is a table for the [tag].
  bool hasTable(String tag) => _tables.containsKey(tag);

  /// Returns the table reader for reading the table with the [tag].
  BinaryReader tableReader(String tag) {
    final t = _tables[tag];
    if (t == null) {
      throw StateError('Font does not contain a "$tag" table');
    }
    return BinaryReader(_data, t.offset, t.length);
  }
}
