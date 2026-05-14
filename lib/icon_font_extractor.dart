/// Public entry points for the `icon_font_extractor` package.
///
/// End users normally don't import anything from this package: they configure
/// `pubspec.yaml` and icon_font_extractor generate` to produce
/// a Dart file with `IconData` constants for each ligature in their font.
///
/// The libraries below are exported for advanced/programmatic use.
library;

export 'src/config.dart';
export 'src/emitter.dart' show emitDartSource;
export 'src/generator.dart';
