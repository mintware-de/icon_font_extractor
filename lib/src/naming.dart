import 'naming_strategy.dart';

/// Sanitises a ligature string into a Dart identifier using the pascal
/// naming strategy with the default `icn` prefix.
///
/// Kept for backward compatibility; prefer [NamingStrategy.toIdentifier].
String toIcnIdentifier(String ligature) =>
    const PascalNamingStrategy().toIdentifier(ligature, 'icn');

/// Deduplicates identifiers in stable order by appending `2`, `3`, …
List<String> deduplicate(Iterable<String> names) {
  final counts = <String, int>{};
  final out = <String>[];
  for (final name in names) {
    final c = counts[name];
    if (c == null) {
      counts[name] = 1;
      out.add(name);
    } else {
      counts[name] = c + 1;
      out.add('$name${c + 1}');
    }
  }
  return out;
}
