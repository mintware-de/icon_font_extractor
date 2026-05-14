## 1.0.0

* Initial release.
* Pure-Dart TTF/OTF parser for the `cmap` and `GSUB` (LookupType 4 and
  LookupType 7-wrapped 4) tables.
* `icon_font_extractor generate` CLI driven by a top-level
  `icon_fonts:` array in `pubspec.yaml`.
* Generates `abstract final class` with `static const IconData` constants
  per ligature, usable directly with Flutter's `Icon` widget.
* `--check` flag for CI to detect stale generated files.
