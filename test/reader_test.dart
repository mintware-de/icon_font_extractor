import 'package:test/test.dart';
import 'package:icon_font_extractor/src/font/reader.dart';

import 'support/byte_writer.dart';

void main() {
  group('BinaryReader', () {
    test('reads big-endian primitives and advances the cursor', () {
      final w = ByteWriter()
        ..u8(0x12)
        ..i16(-1)
        ..u16(0xBEEF)
        ..u24(0xABCDEF)
        ..u32(0xDEADBEEF)
        ..tag('GSUB');
      final r = BinaryReader(w.toByteData());

      expect(r.readUint8(), 0x12);
      expect(r.readInt16(), -1);
      expect(r.readUint16(), 0xBEEF);
      expect(r.readUint24(), 0xABCDEF);
      expect(r.readUint32(), 0xDEADBEEF);
      expect(r.readTag(), 'GSUB');
      expect(r.remaining, 0);
    });

    test('sub() returns an independent window with its own cursor', () {
      final w = ByteWriter()
        ..u16(0xAAAA)
        ..u16(0xBBBB)
        ..u16(0xCCCC);
      final r = BinaryReader(w.toByteData());
      final child = r.sub(2, 2);
      expect(child.length, 2);
      expect(child.readUint16(), 0xBBBB);

      // Parent cursor untouched.
      expect(r.cursor, 0);
      expect(r.readUint16(), 0xAAAA);
    });

    test('skip moves the cursor forward; out-of-range throws', () {
      final w = ByteWriter()
        ..u8(1)
        ..u8(2)
        ..u8(3);
      final r = BinaryReader(w.toByteData());
      r.skip(2);
      expect(r.readUint8(), 3);
      expect(() => r.skip(10), throwsRangeError);
    });
  });
}
