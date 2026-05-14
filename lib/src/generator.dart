import 'dart:io';

import 'config.dart';
import 'emitter.dart';
import 'font/tables/cmap/cmap.dart';
import 'font/tables/gsub/gsub.dart';
import 'font/tables/post.dart';
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

  /// Glyph names that are standard placeholders and should never be emitted
  /// as icon constants when using the cmap/post path.
  static const _skippedGlyphNames = {
    '.notdef',
    '.null',
    'nonmarkingreturn',
    'NULL',
    'CR',
    'space',
    'nbspace',
  };

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

    final warnings = <String>[];
    final entries = <({String ligature, int codepoint})>[];

    if (font.useLigatures) {
      _collectFromLigatures(ttf, cmap, font, warnings, entries);
    } else {
      _collectFromCmap(ttf, cmap, font, warnings, entries);
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

  void _collectFromLigatures(
    TtfFont ttf,
    CmapTable cmap,
    IconFontConfig font,
    List<String> warnings,
    List<({String ligature, int codepoint})> entries,
  ) {
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
  }

  void _collectFromCmap(
    TtfFont ttf,
    CmapTable cmap,
    IconFontConfig font,
    List<String> warnings,
    List<({String ligature, int codepoint})> entries,
  ) {
    // Build glyph ID → name map from the post table.
    final Map<int, String> glyphNames;
    if (ttf.hasTable('post')) {
      final post = PostTable.parse(ttf.tableReader('post'), 0);
      glyphNames = post.glyphNames;
    } else {
      logger(
        'post table missing for ${font.familyName}; '
        'falling back to hex codepoint names.',
      );
      glyphNames = {};
    }

    // Invert cmap: glyph ID → best codepoint.
    final seen = <int>{};
    for (final cp in cmap.codepointToGlyph.keys) {
      final glyphId = cmap.codepointToGlyph[cp]!;
      if (!seen.add(cp)) continue;

      // Resolve the icon name.
      String name;
      final postName = glyphNames[glyphId];
      if (postName != null && !_skippedGlyphNames.contains(postName)) {
        name = postName;
      } else if (postName == null) {
        // No post name — use a hex-based fallback.
        name = 'u${cp.toRadixString(16).toUpperCase()}';
      } else {
        // Name is in the skip list (e.g. .notdef, space).
        continue;
      }

      // Use the best codepoint for this glyph (prefers PUA).
      final bestCp = cmap.bestCodepointFor(glyphId) ?? cp;
      entries.add((ligature: name, codepoint: bestCp));
    }
  }
}
