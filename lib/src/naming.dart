/// Sanitises a ligature string into a Dart identifier:
///   * Whitespace is removed.
///   * Characters invalid in Dart identifiers are replaced with `_`.
///   * The remainder is PascalCased on word boundaries.
///   * The fixed prefix `icn` is prepended.
String toIcnIdentifier(String ligature) {
  final stripped = ligature.replaceAll(RegExp(r'\s+'), '');
  final cleaned = stripped.replaceAllMapped(
    RegExp(r'[^A-Za-z0-9_]'),
    (_) => '_',
  );

  final parts = cleaned
      .split(RegExp(r'[_]+'))
      .where((p) => p.isNotEmpty)
      .toList();

  final pascal = StringBuffer();
  for (final part in parts) {
    pascal.write(part[0].toUpperCase());
    if (part.length > 1) pascal.write(part.substring(1));
  }

  var name = 'icn$pascal';
  if (name == 'icn') {
    name = 'icnEmpty';
  }
  if (RegExp(r'^[0-9]').hasMatch(name)) {
    name = '_$name';
  }
  return name;
}

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
