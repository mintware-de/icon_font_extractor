import 'package:test/test.dart';
import 'package:icon_font_extractor/src/naming.dart';

void main() {
  group('toIcnIdentifier', () {
    test('converts simple lowercase ligature', () {
      expect(toIcnIdentifier('home'), 'icnHome');
    });

    test('PascalCases on underscore boundaries', () {
      expect(toIcnIdentifier('arrow_back_ios'), 'icnArrowBackIos');
    });

    test('PascalCases on dash boundaries (dash becomes _)', () {
      expect(toIcnIdentifier('arrow-back'), 'icnArrowBack');
    });

    test('strips whitespace', () {
      expect(toIcnIdentifier('  home page  '), 'icnHomepage');
    });

    test('replaces other invalid characters with underscore', () {
      expect(toIcnIdentifier('home.page'), 'icnHomePage');
      expect(toIcnIdentifier('home/page'), 'icnHomePage');
    });

    test('preserves digits', () {
      expect(toIcnIdentifier('arrow_2'), 'icnArrow2');
    });

    test('handles empty input', () {
      expect(toIcnIdentifier(''), 'icnEmpty');
      expect(toIcnIdentifier('   '), 'icnEmpty');
    });

    test('handles already PascalCased input', () {
      expect(toIcnIdentifier('ArrowBack'), 'icnArrowBack');
    });
  });

  group('deduplicate', () {
    test('passes through unique names', () {
      expect(deduplicate(['icnHome', 'icnSearch']), ['icnHome', 'icnSearch']);
    });

    test('numbers duplicates starting at 2', () {
      expect(deduplicate(['icnHome', 'icnHome', 'icnHome', 'icnSearch']), [
        'icnHome',
        'icnHome2',
        'icnHome3',
        'icnSearch',
      ]);
    });

    test('does not affect later distinct names', () {
      expect(deduplicate(['a', 'b', 'a', 'c', 'b']), [
        'a',
        'b',
        'a2',
        'c',
        'b2',
      ]);
    });
  });
}
