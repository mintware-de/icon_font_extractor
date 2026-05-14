import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class IconFontConfig {
  IconFontConfig({
    required this.familyName,
    required this.outputPath,
    required this.assetPaths,
  });

  final String familyName;
  final String outputPath;
  final List<String> assetPaths;
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
    configs.add(
      IconFontConfig(familyName: family, outputPath: outputFile, assetPaths: assets),
    );
  }
  return configs;
}
