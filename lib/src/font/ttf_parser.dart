import 'dart:typed_data';

import 'reader.dart';

class TtfTable {
  TtfTable(this.tag, this.offset, this.length);
  final String tag;
  final int offset;
  final int length;
}

/// Parses the sfnt header + table directory of a TTF/OTF font.
class TtfFont {
  TtfFont._(this._data, this.tables);

  final ByteData _data;
  final Map<String, TtfTable> tables;

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

    final tables = <String, TtfTable>{};
    for (var i = 0; i < numTables; i++) {
      final tag = reader.readTag();
      reader.skip(4); // checksum
      final offset = reader.readUint32();
      final length = reader.readUint32();
      tables[tag] = TtfTable(tag, offset, length);
    }
    return TtfFont._(data, tables);
  }

  bool hasTable(String tag) => tables.containsKey(tag);

  BinaryReader tableReader(String tag) {
    final t = tables[tag];
    if (t == null) {
      throw StateError('Font does not contain a "$tag" table');
    }
    return BinaryReader(_data, t.offset, t.length);
  }
}
