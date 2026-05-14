import 'dart:io';

import 'config.dart';
import 'emitter.dart';
import 'font/tables/cmap/cmap.dart';
import 'font/tables/gsub/gsub.dart';
import 'font/ttf_parser.dart';

class GenerationResult {
  GenerationResult({
    required this.familyName,
    required this.outputPath,
    required this.contents,
    required this.iconCount,
    required this.warnings,
  });
  final String familyName;
  final String outputPath;
  final String contents;
  final int iconCount;
  final List<String> warnings;
}

class IconFontGenerator {
  IconFontGenerator({this.logger = print});

  final void Function(String message) logger;

  List<GenerationResult> run(PubspecConfig config) {
    final results = <GenerationResult>[];
    for (final font in config.fonts) {
      results.add(_runOne(config, font));
    }
    return results;
  }

  GenerationResult _runOne(PubspecConfig config, IconFontConfig font) {
    final assetRel = font.assetPaths.first;
    final assetAbs = config.resolve(assetRel);
    final file = File(assetAbs);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Font asset not found for family "${font.familyName}"',
        assetAbs,
      );
    }
    final bytes = file.readAsBytesSync();
    final ttf = TtfFont.parse(bytes);
    if (!ttf.hasTable('cmap')) {
      throw FormatException('Font ${font.familyName} has no cmap table');
    }
    final cmap = CmapTable.parse(ttf.tableReader('cmap'));

    final ligatures = <LigatureEntry>[];
    if (ttf.hasTable('GSUB')) {
      ligatures.addAll(
        GsubTable.extractLigatures(
          ttf.tableReader('GSUB'),
          cmap.glyphToCodepoints,
        ),
      );
    } else {
      logger('GSUB table missing for ${font.familyName}; no ligatures found.');
    }

    final warnings = <String>[];
    final entries = <({String ligature, int codepoint})>[];
    final seen = <String>{};
    for (final lig in ligatures) {
      if (!seen.add(lig.text)) continue;
      final cp = cmap.bestCodepointFor(lig.glyphId);
      if (cp == null) {
        warnings.add(
          'Skipping ligature "${lig.text}": glyph #${lig.glyphId} is not '
          'reachable through the cmap table.',
        );
        continue;
      }
      entries.add((ligature: lig.text, codepoint: cp));
    }

    final source = emitDartSource(
      familyName: font.familyName,
      entries: entries,
      fontFamily: font.outputFamily,
      iconPrefix: font.iconPrefix,
      namingStrategy: font.namingStrategy,
    );

    final outPath = config.resolve(font.outputPath);
    return GenerationResult(
      familyName: font.familyName,
      outputPath: outPath,
      contents: source,
      iconCount: entries.length,
      warnings: warnings,
    );
  }
}
