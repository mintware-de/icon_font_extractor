## 1.2.0

### Format output

Added the `dart_style` package to format the generated Dart code.

## 1.1.0

### Non-Ligature Font support

Non-Ligature fonts are now supported. Just add the `useLigatures: false` to the `icon_font_extractor` config and you're
good.

## 1.0.0

* Initial release.
* Pure-Dart TTF/OTF parser for the `cmap` and `GSUB` (LookupType 4 and
  LookupType 7-wrapped 4) tables.
* `icon_font_extractor generate` CLI driven by a top-level
  `icon_fonts:` array in `pubspec.yaml`.
* Generates `abstract final class` with `static const IconData` constants
  per ligature, usable directly with Flutter's `Icon` widget.
* `--check` flag for CI to detect stale generated files.
