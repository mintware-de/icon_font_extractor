/// Strategies for converting a raw ligature string into a Dart identifier.
///
/// Each strategy handles whitespace removal, character sanitisation, and
/// camelCase boundary detection internally. The [prefix] is treated as the
/// leading word(s) — the naming strategy is applied uniformly to the entire
/// word sequence (prefix + ligature).
abstract interface class NamingStrategy {
  const NamingStrategy();

  /// Returns a valid Dart identifier for [ligature] with [prefix] as the
  /// leading word(s). The strategy's casing rules apply to all words.
  String toIdentifier(String ligature, String prefix);
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Splits a string into words by:
/// 1. Removing whitespace.
/// 2. Replacing characters that are invalid in Dart identifiers with `_`.
/// 3. Inserting `_` at camelCase/PascalCase word boundaries.
/// 4. Splitting on `_` and discarding empty parts.
List<String> _splitToWords(String s) {
  if (s.isEmpty) return [];
  final stripped = s.replaceAll(RegExp(r'\s+'), '');
  // Replace non-identifier characters (keep letters, digits, _) with _.
  final cleaned = stripped.replaceAllMapped(
    RegExp(r'[^A-Za-z0-9_]'),
    (_) => '_',
  );
  // Insert _ before camelCase boundaries:
  //   "IOSDevice" → "IOS_Device"  (acronym before word)
  //   "arrowBack" → "arrow_Back"  (lowercase→uppercase transition)
  final withBoundaries = cleaned
      .replaceAllMapped(
        RegExp(r'([A-Z]+)([A-Z][a-z])'),
        (m) => '${m[1]}_${m[2]}',
      )
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}');
  return withBoundaries
      .split(RegExp(r'_+'))
      .where((p) => p.isNotEmpty)
      .toList();
}

/// Normalises a word to Title Case: lowercases it entirely then uppercases
/// the first character. E.g. `ADDRESS` → `Address`, `back` → `Back`.
String _capitalize(String word) {
  if (word.isEmpty) return '';
  final lower = word.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

/// Prepends `_` when the first character is a digit.
String _guardDigit(String name) =>
    RegExp(r'^[0-9]').hasMatch(name) ? '_$name' : name;

/// Combines [prefix] words and [ligature] words into one ordered list.
/// Falls back to `['empty']` for the ligature part when it is empty.
List<String> _allWords(String prefix, String ligature) {
  final pw = _splitToWords(prefix);
  final lw = _splitToWords(ligature);
  return [
    ...pw,
    ...(lw.isEmpty ? ['empty'] : lw),
  ];
}

// ---------------------------------------------------------------------------
// Strategy implementations
// ---------------------------------------------------------------------------

/// Converts all words (prefix + ligature) to **PascalCase**.
///
/// Example: `arrow_back_ios` + prefix `icn` → `IcnArrowBackIos`
class PascalNamingStrategy implements NamingStrategy {
  /// Constructor
  const PascalNamingStrategy();

  @override
  String toIdentifier(String ligature, String prefix) {
    final words = _allWords(prefix, ligature);
    if (words.isEmpty) return 'Empty';
    return _guardDigit(words.map(_capitalize).join(''));
  }
}

/// Converts all words to **camelCase**: first word lowercase, the rest
/// PascalCased.
///
/// Example: `arrow_back_ios` + prefix `icn` → `icnArrowBackIos`
class CamelNamingStrategy implements NamingStrategy {
  /// Constructor
  const CamelNamingStrategy();

  @override
  String toIdentifier(String ligature, String prefix) {
    final words = _allWords(prefix, ligature);
    if (words.isEmpty) return 'empty';
    final first = words.first.toLowerCase();
    final rest = words.skip(1).map(_capitalize).join('');
    return _guardDigit('$first$rest');
  }
}

/// Converts all words to **snake_case**.
///
/// Example: `arrow_back_ios` + prefix `icn` → `icn_arrow_back_ios`
class SnakeNamingStrategy implements NamingStrategy {
  /// Constructor
  const SnakeNamingStrategy();

  @override
  String toIdentifier(String ligature, String prefix) {
    final words = _allWords(prefix, ligature);
    if (words.isEmpty) return 'empty';
    return _guardDigit(words.map((w) => w.toLowerCase()).join('_'));
  }
}

/// Keeps the ligature **as-is** (only sanitises invalid characters) and
/// prepends [prefix] directly.
///
/// Example: `arrow_back_iOS` + prefix `icn` → `icnarrow_back_iOS`
class KeepNamingStrategy implements NamingStrategy {
  /// Constructor
  const KeepNamingStrategy();

  @override
  String toIdentifier(String ligature, String prefix) {
    final sanitized = ligature
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAllMapped(RegExp(r'[^A-Za-z0-9_]'), (_) => '_');
    if (sanitized.isEmpty || sanitized.replaceAll('_', '').isEmpty) {
      return '${prefix}empty';
    }
    return _guardDigit('$prefix$sanitized');
  }
}

// ---------------------------------------------------------------------------
// Factory helper
// ---------------------------------------------------------------------------

/// Parses a strategy name string (case-insensitive) into the corresponding
/// [NamingStrategy]. Throws [FormatException] for unknown values.
///
/// Valid values: `pascal`, `camel`, `snake`, `keep`.
NamingStrategy namingStrategyFromString(String value) {
  switch (value.toLowerCase()) {
    case 'pascal':
      return const PascalNamingStrategy();
    case 'camel':
      return const CamelNamingStrategy();
    case 'snake':
      return const SnakeNamingStrategy();
    case 'keep':
      return const KeepNamingStrategy();
    default:
      throw FormatException(
        'Unknown naming strategy "$value". '
        'Valid values are: pascal, camel, snake, keep.',
      );
  }
}
