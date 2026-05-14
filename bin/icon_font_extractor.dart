import 'dart:io';

import 'package:args/args.dart';
import 'package:icon_font_extractor/src/config.dart';
import 'package:icon_font_extractor/src/generator.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'pubspec',
      abbr: 'p',
      defaultsTo: 'pubspec.yaml',
      help: 'Path to the pubspec.yaml to read.',
    )
    ..addFlag(
      'check',
      negatable: false,
      help:
          'Do not write files; exit non-zero if any output would change. '
          'Useful in CI to ensure generated files are committed.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print extra diagnostic output.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage and exit.',
    );

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }

  if (args['help'] as bool) {
    stdout.writeln('Usage: icon_font_extractor generate [options]');
    stdout.writeln(parser.usage);
    return;
  }

  final pubspecPath = args['pubspec'] as String;
  final verbose = args['verbose'] as bool;
  final check = args['check'] as bool;

  final PubspecConfig config;
  try {
    config = PubspecConfig.load(pubspecPath);
  } catch (e) {
    stderr.writeln('error: $e');
    exit(1);
  }

  if (config.fonts.isEmpty) {
    stderr.writeln(
      'No icon_fonts entries found in $pubspecPath; nothing to do.',
    );
    exit(1);
  }

  final generator = IconFontGenerator(
    logger: verbose ? stdout.writeln : (_) {},
  );

  var changed = false;
  var hadWarnings = false;
  try {
    final results = generator.run(config);
    for (final r in results) {
      for (final w in r.warnings) {
        hadWarnings = true;
        stderr.writeln('warning [${r.familyName}]: $w');
      }
      final outFile = File(r.outputPath);
      final existing = outFile.existsSync() ? outFile.readAsStringSync() : null;
      final isStale = existing != r.contents;
      if (check) {
        if (isStale) {
          changed = true;
          stderr.writeln(
            '${r.outputPath} is out of date for family "${r.familyName}".',
          );
        } else if (verbose) {
          stdout.writeln('${r.outputPath} up-to-date (${r.iconCount} icons).');
        }
      } else {
        if (isStale) {
          outFile.parent.createSync(recursive: true);
          outFile.writeAsStringSync(r.contents);
          stdout.writeln(
            'Generated ${r.outputPath} (${r.iconCount} icons, family "${r.familyName}").',
          );
        } else if (verbose) {
          stdout.writeln('${r.outputPath} unchanged (${r.iconCount} icons).');
        }
      }
    }
  } catch (e, st) {
    stderr.writeln('error: $e');
    if (verbose) stderr.writeln(st);
    exit(1);
  }

  if (check && changed) exit(1);
  if (hadWarnings && verbose) {
    stdout.writeln('Completed with warnings.');
  }
}
