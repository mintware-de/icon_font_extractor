import 'package:test/test.dart';
import 'package:icon_font_extractor/src/emitter.dart';

void main() {
  group('emitDartSource', () {
    test('emits header, class, and IconData entries sorted by ligature', () {
      final src = emitDartSource(
        familyName: 'MyIcons',
        entries: [
          (ligature: 'search', codepoint: 0xE901),
          (ligature: 'home', codepoint: 0xE900),
        ],
      );

      expect(src, contains('// GENERATED CODE - DO NOT MODIFY BY HAND.'));
      expect(src, contains("import 'package:flutter/widgets.dart';"));
      expect(src, contains('@staticIconProvider'));
      expect(src, contains('abstract final class MyIcons {'));
      expect(src, contains('MyIcons._();'));
      expect(
        src,
        contains(
          "static const IconData icn_home = IconData(0xE900, fontFamily: 'MyIcons');",
        ),
      );
      expect(
        src,
        contains(
          "static const IconData icn_search = IconData(0xE901, fontFamily: 'MyIcons');",
        ),
      );

      // Sorted: home appears before search.
      expect(src.indexOf('icn_home'), lessThan(src.indexOf('icn_search')));
    });

    test('disambiguates colliding identifiers', () {
      final src = emitDartSource(
        familyName: 'F',
        entries: [
          (ligature: 'home', codepoint: 0xE001),
          (ligature: '_home', codepoint: 0xE002),
          (ligature: 'home_', codepoint: 0xE003),
        ],
      );
      // All three sanitise to icn_home; later ones get suffixed.
      expect(src, contains('icn_home '));
      expect(src, contains('icn_home2'));
      expect(src, contains('icn_home3'));
    });

    test('produces empty class when no entries', () {
      final src = emitDartSource(familyName: 'Empty', entries: const []);
      expect(src, contains('abstract final class Empty {'));
      expect(src, isNot(contains('static const IconData')));
    });
  });
}
