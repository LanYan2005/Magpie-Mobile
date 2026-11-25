# Magpie brand assets — provenance and usage notes

## Source

- Upstream project: `yetone/magpie`
- Upstream commit: `95e6a4180866afde186e0f1a25369388c7fd7e7f`
- Upstream file: `build/icon/magpie.svg`
- Local verification copy: `_tmp_pack_extract/magpie_src.svg`
- Git blob SHA: `f6b9ceb1fa9f95410e1a08a116cc85d39284c7df`
  (independently re-verified in this session with `git hash-object`;
  matches byte-for-byte)

A second file, `_tmp_pack_extract/magpie_src.png` (blob
`4569d855d22ae1b47149e3040900c4cc58a5db82`, also re-verified with
`git hash-object`), was inspected and **not** used as the primary source.
It is a 1024x1024 RGBA layer with ~84% fully-transparent pixels, ~15%
fully-opaque black, and a small fraction of partial-alpha edge pixels
(content bounding box `(112, 205)-(911, 820)`) — characteristic of a
single layer exported from macOS Icon Composer (`.icon`/`.iconset`
source), not a finished, standalone app icon. Its silhouette bounding-box
aspect ratio (1.2992) matches the SVG's rendered aspect ratio (1.2995,
diff 0.02%) confirming both files depict the same mark, but the SVG was
preferred as the faithful, resolution-independent, finished vector mark.

## What was generated here

All assets below are **local derivatives**, rasterized offline from the
verified upstream SVG. No upstream PNG pixels were copied; no files were
downloaded; no new dependencies were installed. Rasterization used a
purpose-built even-odd scanline renderer (PIL + numpy, both already
present in the environment) that parses the SVG's `M`/`C`/`Z` path
commands directly and flattens cubic Beziers, reproducing
`fill-rule="evenodd"` semantics exactly. Output was cross-checked against
a known-good preview composite and against the upstream PNG layer's
bounding-box aspect ratio (see above).

- `assets/brand/magpie.png`
  1024x1024, RGBA, transparent background, opaque black mark, **no
  added padding** — the mark's native proportions from the SVG viewBox
  are preserved as-is. Used in-app via `Image.asset('assets/brand/magpie.png')`
  in `lib/widgets/app_canvas.dart` (`BrandLockup`), composited at ~28-34
  logical px over the app's theme background.

  Caveat: the mark is rendered in a single fixed color (opaque black),
  faithful to the upstream SVG which has no explicit `fill` (SVG default
  fill is black). The app's theme (`lib/core/magpie_theme.dart`) has a
  dark mode; a solid black mark will have low contrast on dark
  backgrounds. No dark-mode variant was created, since that would be a
  new derivative decision beyond "faithful reproduction of the approved
  upstream mark" and beyond this task's scope — flagging for the app
  owner to decide (e.g. wrap in a light-colored container, or request a
  separate light-on-dark variant).

- `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`
  Opaque RGB (no alpha channel — Android legacy launcher icons are
  rendered without transparency by convention), white background, mark
  centered with ~12% padding on each side. Sizes: 48/72/96/144/192 px,
  matching the pre-existing file sizes exactly (only pixel content was
  replaced; no new density buckets, no new files, no manifest/gradle
  changes). These replace the default Flutter template icon (Flutter's
  own blue logo), which was still in place before this change.
  No `ic_launcher_round` or adaptive-icon (`mipmap-anydpi-v26`) resources
  exist in this project, so none were added — square legacy icon only,
  matching existing project structure.

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (15 files)
  Opaque RGB (no alpha — Apple's App Store/Xcode icon validation rejects
  icons with an alpha channel), white background, mark centered with ~8%
  padding (tighter than Android since iOS applies its own corner-rounding
  mask on top). Sizes match `Contents.json` exactly: 20/29/40/58/60/76/
  80/87/120/152/167/180/1024 px. These replace the default Flutter
  template icon. `Contents.json` itself was not modified (filenames and
  slots unchanged).

## License and attribution

The upstream SVG and the repository's MIT license were verified against the
pinned commit above. See [Third-party notices](../../THIRD_PARTY_NOTICES.md)
for the upstream copyright and license text. These mobile icon derivatives
are not official Magpie launcher art. Trademark rights are not granted by
the MIT software license, and this project is not affiliated with or
endorsed by upstream.

## Regeneration

The rasterizer and generator scripts used to produce these assets were
written to a temp directory outside this repository (not committed, not
part of this repo) because the task's source directory
(`_tmp_pack_extract/`) is treated as untrusted archive data and was not
executed. To regenerate, re-derive an equivalent even-odd SVG path
rasterizer against `_tmp_pack_extract/magpie_src.svg` (viewBox `0 0 44
44`, single `<path fill-rule="evenodd">`, verified blob
`f6b9ceb1fa9f95410e1a08a116cc85d39284c7df`).
