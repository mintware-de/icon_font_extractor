# icon_font_extractor

Generate strongly-typed `IconData` constants from any icon font's **ligature
table** (GSUB). Drop a font into your `pubspec.yaml`, add a single
`icon_fonts:` entry, run a command, and use the icons with Flutter's built-in
`Icon` widget — no boilerplate, no hand-curated codepoint maps.

## Why?

Icon fonts (Material Icons, Material Symbols, custom Figma exports from
IcoMoon / Fontello, FontAwesome Pro…) ship a GSUB *ligature substitution* table that maps
human-readable strings like `"home"`, `"arrow_back"`, `"settings_outlined"`
to glyphs. Flutter's `Icon` widget renders glyphs by codepoint, not by
ligature, which means you normally have to hand-write or copy/paste a
`static const IconData` for every icon you use.

`icon_font_extractor` reads the font's GSUB + cmap tables in pure Dart and
emits that boilerplate for you.

Plus: Flutters Tree-Shaking for icons works out-of-the-box!

## Install

You don't even need to install that package inside your app. Just install it globally with

```bash
dart pub global activate icon_font_extractor
```

## Configure

Update your Apps `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: MaterialIcons # <-- Add your icon font
      fonts:
        - asset: assets/fonts/MaterialIcons-Regular.otf

# Run `icon_font_extractor generate` from this directory after
# `flutter pub get` to (re)generate `lib/material_icons.dart`.
icon_fonts:
  - family: MaterialIcons        # must match a family under flutter.fonts
    outputFile: lib/material_icons.g.dart
    # outputFamily: MaterialSymbols  # optional: overrides fontFamily in generated IconData
    # iconPrefix: icn               # optional: identifier prefix (default: icn)
    # naming: snake                # optional: snake (default), pascal, camel, keep
```


## Generate

```bash
# Run
icon_font_extractor generate
```

You'll get a generated file like:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND.
import 'package:flutter/widgets.dart';

@staticIconProvider
abstract final class MyIcons {
  MyIcons._();

  /// Ligature: `home`
  static const IconData icnHome = IconData(0xE900, fontFamily: 'MyIcons');

  /// Ligature: `search`
  static const IconData icnSearch = IconData(0xE901, fontFamily: 'MyIcons');
  // ...
}
```

## Use

```dart
Icon(MyIcons.icnHome, size: 32, color: Colors.blue)
```

That's it — the generated `IconData` works with every existing Flutter widget
that accepts `IconData` (`Icon`, `IconButton`, `BottomNavigationBarItem`, …).

## CLI flags

| Flag | Description |
| --- | --- |
| `--pubspec <path>` | Path to the pubspec.yaml (default: `pubspec.yaml`). |
| `--check` | Don't write; exit non-zero if any output would change. CI-friendly. |
| `--verbose` | Extra diagnostic output. |
| `--help` | Show usage. |

## Naming rules

The `iconPrefix` key (default `icn`) is prepended to every identifier. The
`naming` key controls how ligature words are cased:

| Strategy | Example ligature | Result (prefix `icn`) |
| --- | --- | --- |
| `snake` *(default)* | `arrow_back_ios` | `icn_arrow_back_ios` |
| `pascal` | `arrow_back_ios` | `IcnArrowBackIos` |
| `camel` | `arrow_back_ios` | `icnArrowBackIos` |
| `keep` | `arrowBack_iOS` | `icnarrowBack_iOS` |

Additional sanitisation applied for all strategies:

* Whitespace is removed.
* Characters that are not valid in a Dart identifier are replaced with `_`.
* Duplicate identifiers are disambiguated with a numeric suffix
  (`icnHome`, `icnHome2`, `icnHome3`, …).

## How codepoints are chosen

For each ligature, the generator looks up the substituted glyph and finds the
codepoint that maps to it via the font's `cmap` table, preferring the
Unicode Private Use Areas. If a glyph is unreachable from `cmap`, the
generator emits a warning and skips that ligature (the `Icon` widget can only
render codepoints that are present in the font's `cmap`).

## Limitations

* Only LookupType 4 (Ligature Substitution) is read from GSUB; LookupType 7
  (Extension Substitution) wrappers around type 4 are unwrapped automatically.
* Contextual / chained substitutions are not consulted.
* TrueType collections (`ttcf`) are not supported — point at a single-font
  TTF/OTF.

## License

MIT — see `LICENSE`.
