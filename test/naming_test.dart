import 'package:test/test.dart';
import 'package:icon_font_extractor/src/naming.dart';
import 'package:icon_font_extractor/src/naming_strategy.dart';

void main() {
  // toIcnIdentifier delegates to PascalNamingStrategy(prefix:'icn').
  // Pascal now applies to ALL words including the prefix, so 'icn' → 'Icn'.
  group('toIcnIdentifier', () {
    test('converts simple lowercase ligature', () {
      expect(toIcnIdentifier('home'), 'IcnHome');
    });

    test('PascalCases on underscore boundaries', () {
      expect(toIcnIdentifier('arrow_back_ios'), 'IcnArrowBackIos');
    });

    test('PascalCases on dash boundaries (dash becomes _)', () {
      expect(toIcnIdentifier('arrow-back'), 'IcnArrowBack');
    });

    test('strips whitespace', () {
      expect(toIcnIdentifier('  home page  '), 'IcnHomepage');
    });

    test('replaces other invalid characters with underscore', () {
      expect(toIcnIdentifier('home.page'), 'IcnHomePage');
      expect(toIcnIdentifier('home/page'), 'IcnHomePage');
    });

    test('preserves digits', () {
      expect(toIcnIdentifier('arrow_2'), 'IcnArrow2');
    });

    test('handles empty input', () {
      expect(toIcnIdentifier(''), 'IcnEmpty');
      expect(toIcnIdentifier('   '), 'IcnEmpty');
    });

    test('handles already PascalCased input', () {
      expect(toIcnIdentifier('ArrowBack'), 'IcnArrowBack');
    });
  });

  group('deduplicate', () {
    test('passes through unique names', () {
      expect(deduplicate(['IcnHome', 'IcnSearch']), ['IcnHome', 'IcnSearch']);
    });

    test('numbers duplicates starting at 2', () {
      expect(
        deduplicate(['IcnHome', 'IcnHome', 'IcnHome', 'IcnSearch']),
        ['IcnHome', 'IcnHome2', 'IcnHome3', 'IcnSearch'],
      );
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

  group('PascalNamingStrategy', () {
    const s = PascalNamingStrategy();

    test('simple ligature', () => expect(s.toIdentifier('home', 'icn'), 'IcnHome'));
    test('underscore words', () => expect(s.toIdentifier('arrow_back_ios', 'icn'), 'IcnArrowBackIos'));
    test('dash becomes word boundary', () => expect(s.toIdentifier('arrow-back', 'icn'), 'IcnArrowBack'));
    test('ALL_CAPS normalized', () => expect(s.toIdentifier('ADDRESS-BOOK', 'icn'), 'IcnAddressBook'));
    test('camelCase boundary split', () => expect(s.toIdentifier('ArrowBack', 'icn'), 'IcnArrowBack'));
    test('empty ligature', () => expect(s.toIdentifier('', 'icn'), 'IcnEmpty'));
    test('custom prefix', () => expect(s.toIdentifier('home', 'icon'), 'IconHome'));
    test('empty prefix', () => expect(s.toIdentifier('home', ''), 'Home'));
  });

  group('CamelNamingStrategy', () {
    const s = CamelNamingStrategy();

    test('simple ligature', () => expect(s.toIdentifier('home', 'icn'), 'icnHome'));
    test('underscore words', () => expect(s.toIdentifier('arrow_back_ios', 'icn'), 'icnArrowBackIos'));
    test('dash becomes word boundary', () => expect(s.toIdentifier('arrow-back', 'icn'), 'icnArrowBack'));
    test('ALL_CAPS normalized', () => expect(s.toIdentifier('ADDRESS-BOOK', 'icn'), 'icnAddressBook'));
    test('camelCase boundary split', () => expect(s.toIdentifier('ArrowBack', 'icn'), 'icnArrowBack'));
    test('empty ligature', () => expect(s.toIdentifier('', 'icn'), 'icnEmpty'));
    test('custom prefix', () => expect(s.toIdentifier('home', 'icon'), 'iconHome'));
    test('empty prefix', () => expect(s.toIdentifier('arrow_back', ''), 'arrowBack'));
  });

  group('SnakeNamingStrategy', () {
    const s = SnakeNamingStrategy();

    test('simple ligature', () => expect(s.toIdentifier('home', 'icn'), 'icn_home'));
    test('underscore words', () => expect(s.toIdentifier('arrow_back_ios', 'icn'), 'icn_arrow_back_ios'));
    test('dash becomes word boundary', () => expect(s.toIdentifier('arrow-back', 'icn'), 'icn_arrow_back'));
    test('ALL_CAPS normalized', () => expect(s.toIdentifier('ADDRESS-BOOK', 'icn'), 'icn_address_book'));
    test('camelCase boundary split', () => expect(s.toIdentifier('ArrowBack', 'icn'), 'icn_arrow_back'));
    test('empty ligature', () => expect(s.toIdentifier('', 'icn'), 'icn_empty'));
    test('custom prefix', () => expect(s.toIdentifier('home', 'icon'), 'icon_home'));
    test('empty prefix', () => expect(s.toIdentifier('arrow_back', ''), 'arrow_back'));
  });

  group('KeepNamingStrategy', () {
    const s = KeepNamingStrategy();

    test('keeps casing as-is', () => expect(s.toIdentifier('arrowBack', 'icn'), 'icnarrowBack'));
    test('preserves underscores', () => expect(s.toIdentifier('arrow_back_ios', 'icn'), 'icnarrow_back_ios'));
    test('replaces invalid chars', () => expect(s.toIdentifier('home-page', 'icn'), 'icnhome_page'));
    test('empty ligature', () => expect(s.toIdentifier('', 'icn'), 'icnempty'));
    test('empty prefix', () => expect(s.toIdentifier('home', ''), 'home'));
  });

  group('namingStrategyFromString', () {
    test('pascal', () => expect(namingStrategyFromString('pascal'), isA<PascalNamingStrategy>()));
    test('camel', () => expect(namingStrategyFromString('camel'), isA<CamelNamingStrategy>()));
    test('snake', () => expect(namingStrategyFromString('snake'), isA<SnakeNamingStrategy>()));
    test('keep', () => expect(namingStrategyFromString('keep'), isA<KeepNamingStrategy>()));
    test('case-insensitive', () => expect(namingStrategyFromString('PASCAL'), isA<PascalNamingStrategy>()));
    test('unknown throws', () => expect(() => namingStrategyFromString('unknown'), throwsFormatException));
  });
}
