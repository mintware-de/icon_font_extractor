import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'naming_strategy.dart';

class IconFontConfig {
  IconFontConfig({
    required this.familyName,
    required this.outputPath,
    required this.assetPaths,
    this.outputFamily,
    String? iconPrefix,
    NamingStrategy? namingStrategy,
    bool? useLigatures,
  })  : iconPrefix = iconPrefix ?? 'icn',
        namingStrategy = namingStrategy ?? const SnakeNamingStrategy(),
        useLigatures = useLigatures ?? true;

  final String familyName;
  final String outputPath;
  final List<String> assetPaths;

  /// When set, overrides the `fontFamily` value written into every generated
  /// `IconData` constant. Defaults to [familyName] when null.
  final String? outputFamily;

  /// Prefix prepended to every generated identifier. Defaults to `icn`.
  final String iconPrefix;

  /// Strategy used to convert ligature names to Dart identifiers.
  /// Defaults to [SnakeNamingStrategy].
  final NamingStrategy namingStrategy;

  /// When `true` (default), icon names are read from the GSUB ligature table.
  /// When `false`, names are read from the `post` table glyph names, keyed by
  /// codepoints in the `cmap` table. Use this for fonts that have no ligature
  /// table but carry meaningful glyph names.
  final bool useLigatures;
}

class PubspecConfig {
  PubspecConfig._(this.pubspecDir, this.fonts);

  factory PubspecConfig.load(String pubspecPath) {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      throw FileSystemException('pubspec.yaml not found', pubspecPath);
    }
    final yaml = loadYaml(file.readAsStringSync());
    if (yaml is! YamlMap) {
      throw const FormatException('pubspec.yaml is not a YAML mapping');
    }

    final iconFonts = _extractIconFonts(yaml);
    final familyToAssets = _extractFamilyAssets(yaml);
    final configs = _buildFontConfigs(iconFonts, familyToAssets);
    final dir = p.dirname(p.absolute(pubspecPath));
    return PubspecConfig._(dir, configs);
  }

  final String pubspecDir;
  final List<IconFontConfig> fonts;

  String resolve(String relative) => p.normalize(p.join(pubspecDir, relative));
}

/// Extracts and validates the top-level `icon_fonts:` list.
YamlList _extractIconFonts(YamlMap yaml) {
  final iconFonts = yaml['icon_fonts'];
  if (iconFonts == null) {
    throw const FormatException(
      'No top-level "icon_fonts:" key found in pubspec.yaml. '
      'Add e.g.\n'
      '  icon_fonts:\n'
      '    - family: MyIcons\n'
      '      outputFile: lib/my_icons.g.dart',
    );
  }
  if (iconFonts is! YamlList) {
    throw const FormatException(
      '"icon_fonts:" must be a list of objects with "family" and "outputFile" keys.',
    );
  }
  return iconFonts;
}

/// Reads `flutter.fonts` and builds a map of family name → asset paths.
Map<String, List<String>> _extractFamilyAssets(YamlMap yaml) {
  final flutterSection = yaml['flutter'];
  final fontsList =
      flutterSection is YamlMap ? flutterSection['fonts'] : null;
  if (fontsList is! YamlList) return {};

  final familyToAssets = <String, List<String>>{};
  for (final entry in fontsList) {
    if (entry is! YamlMap) continue;
    final family = entry['family'];
    final fonts = entry['fonts'];
    if (family is! String || fonts is! YamlList) continue;
    final paths = [
      for (final f in fonts)
        if (f is YamlMap && f['asset'] is String) f['asset'] as String,
    ];
    if (paths.isNotEmpty) familyToAssets[family] = paths;
  }
  return familyToAssets;
}

/// Builds an [IconFontConfig] for each entry in [iconFonts], cross-referencing
/// [familyToAssets] to resolve asset file paths.
List<IconFontConfig> _buildFontConfigs(
  YamlList iconFonts,
  Map<String, List<String>> familyToAssets,
) {
  final configs = <IconFontConfig>[];
  for (final entry in iconFonts) {
    if (entry is! YamlMap) {
      throw FormatException(
        '"icon_fonts" entries must be objects with "family" and "outputFile" keys, got $entry',
      );
    }
    final family = entry['family'];
    final outputFile = entry['outputFile'];
    if (family is! String || outputFile is! String) {
      throw FormatException(
        '"icon_fonts" entry must have string "family" and "outputFile" keys, got $entry',
      );
    }
    final assets = familyToAssets[family];
    if (assets == null || assets.isEmpty) {
      throw FormatException(
        'icon_fonts contains "$family" but no matching font family is '
        'declared under flutter.fonts in pubspec.yaml.',
      );
    }
    final outputFamily = entry['outputFamily'];
    if (outputFamily != null && outputFamily is! String) {
      throw FormatException(
        '"icon_fonts" entry "outputFamily" must be a string, got $outputFamily',
      );
    }
    final iconPrefix = entry['iconPrefix'];
    if (iconPrefix != null && iconPrefix is! String) {
      throw FormatException(
        '"icon_fonts" entry "iconPrefix" must be a string, got $iconPrefix',
      );
    }
    final namingValue = entry['naming'];
    if (namingValue != null && namingValue is! String) {
      throw FormatException(
        '"icon_fonts" entry "naming" must be a string '
        '(pascal, camel, snake, or keep), got $namingValue',
      );
    }
    final NamingStrategy? namingStrategy;
    try {
      namingStrategy = namingValue != null
          ? namingStrategyFromString(namingValue as String)
          : null;
    } on FormatException catch (e) {
      throw FormatException(
        '"icon_fonts" entry "naming": ${e.message}',
      );
    }
    final useLigaturesValue = entry['useLigatures'];
    if (useLigaturesValue != null && useLigaturesValue is! bool) {
      throw FormatException(
        '"icon_fonts" entry "useLigatures" must be a boolean, got $useLigaturesValue',
      );
    }
    configs.add(
      IconFontConfig(
        familyName: family,
        outputPath: outputFile,
        assetPaths: assets,
        outputFamily: outputFamily as String?,
        iconPrefix: iconPrefix as String?,
        namingStrategy: namingStrategy,
        useLigatures: useLigaturesValue as bool?,
      ),
    );
  }
  return configs;
}
