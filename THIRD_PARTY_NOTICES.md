# Third-party notices

Magpie mark: yetone/magpie, build/icon/magpie.svg at commit 95e6a4180866afde186e0f1a25369388c7fd7e7f.

The Flutter Agent list adapts the row layout, field order, and disclosure interactions from `renderAgents` in [app.js](https://github.com/yetone/magpie/blob/eab4b006d52b818cd91bd2d10b3918782cf535db/internal/gui/assets/app.js#L492) and the Agent list styles in [app.css](https://github.com/yetone/magpie/blob/eab4b006d52b818cd91bd2d10b3918782cf535db/internal/gui/assets/app.css#L775).

The Flutter navigation references the title bar and sidebar in [app.js](https://github.com/yetone/magpie/blob/b711745b69a551b95b8a59a694c205f6ff3556ca/internal/gui/assets/app.js#L23947) and [app.css](https://github.com/yetone/magpie/blob/b711745b69a551b95b8a59a694c205f6ff3556ca/internal/gui/assets/app.css#L241) at commit `b711745b69a551b95b8a59a694c205f6ff3556ca`.

The Flutter UI refresh references the [upstream GUI markup](https://github.com/yetone/magpie/blob/6346f3835092400206f330ddf4a4fe1eaef1dc73/internal/gui/assets/index.html), [styles](https://github.com/yetone/magpie/blob/6346f3835092400206f330ddf4a4fe1eaef1dc73/internal/gui/assets/app.css), and [interactions](https://github.com/yetone/magpie/blob/6346f3835092400206f330ddf4a4fe1eaef1dc73/internal/gui/assets/app.js) at commit `6346f3835092400206f330ddf4a4fe1eaef1dc73`.

## Bundled upstream UI icons

`assets/upstream/ui/` contains SVGs extracted from the local `magpie-research/upstream/` snapshot of `yetone/magpie`:

| Assets | Exact source in the snapshot |
| --- | --- |
| `nav-*.svg` | `index.html` lines 75–88, the `<svg>` in each `#nav button[data-view]`; filenames use the upstream view names. |
| `sidebar-open.svg`, `sidebar-closed.svg` | `index.html` line 63 (`#sideToggle`); `app.css` lines 650–651 set the pane opacity to `.32` when shown and `0` when hidden. This CSS state is embedded in the two SVGs. |
| `magpie.svg` | `index.html` line 66 (`.brand .logo`, `path#bird`, rendered by `use.whole`); the web-only animated layers are omitted. |
| `back.svg`, `search.svg`, `settings.svg`, `eye-off.svg` | `index.html` lines 71 (`#navBack`), 112 (`#find`), 115 (`#prefs`) and 158 (`#pvMask`), respectively. |
| `chevron-right.svg`, `cross.svg`, `plus.svg`, `pencil.svg` | `app.js` `svg()` at lines 283–289 and `CHEV_R`, `CROSS`, `PLUS`, `PENCIL` at lines 294, 296, 297 and 304; stroke widths follow the calls at lines 6251, 19707, 7311 and 15277, respectively. |
| `provider-generic.svg` | `app.js` lines 379–387, `icon("generic")`. |
| `eye.svg` | `app.js` line 24703 (`EYE`, the 24 × 24 account-mask version). |

Snapshot SHA-256: `index.html` `b95bd6562253041a1309cb6b94c78de57b546d18c8391d9417b857b4e3496180`; `app.js` `6728cba7e811e1e374421177df3f4f38ef7a6467c739a713c659d41451ba58b6`; `app.css` `6a847624d9cfb2d04399c6a04e9c5f4d0d87cd854110fa999d1361f0329c345c`. The extracted SVGs keep the original geometry and use Flutter's icon foreground for `currentColor`.

## Bundled provider logos

`assets/upstream/vendors/` contains SVGs from the [Magpie icon directory](https://github.com/yetone/magpie/tree/6346f3835092400206f330ddf4a4fe1eaef1dc73/internal/gui/assets/icons) at commit `6346f3835092400206f330ddf4a4fe1eaef1dc73` (see also the [upstream provider presets](https://github.com/yetone/magpie/blob/6346f3835092400206f330ddf4a4fe1eaef1dc73/internal/provider/presets.go)). Files are byte-for-byte copies, named after the corresponding Flutter directory IDs:

| Local filename | Upstream filename | Rendering |
| --- | --- | --- |
| `anthropic.svg` | `claude-color.svg` | Original colors |
| `google.svg` | `gemini-color.svg` | Original colors |
| `deepseek.svg` | `deepseek-color.svg` | Original colors |
| `mistral.svg` | `mistral-color.svg` | Original colors |
| `qwen.svg` | `qwen-color.svg` | Original colors |
| `together.svg` | `together-color.svg` | Original colors |
| `fireworks.svg` | `fireworks-color.svg` | Original colors |
| `siliconflow.svg` | `siliconcloud-color.svg` | Original colors |
| `moonshot.svg` | `kimi.svg` | Theme foreground |
| `remote.svg` | `magpie.svg` | Theme foreground |
| `openai.svg`, `xai.svg`, `groq.svg`, `openrouter.svg`, `vercel.svg`, `ollama.svg`, `lmstudio.svg` | Same filenames | Theme foreground |

The asset directory includes the [Magpie MIT license](https://github.com/yetone/magpie/blob/6346f3835092400206f330ddf4a4fe1eaef1dc73/LICENSE) and [Lobe Icons MIT license](https://github.com/lobehub/lobe-icons/blob/05260484d9f4de68f90cc87a634ae68fa4043efd/LICENSE) for the vendor artwork bundled by upstream. Provider marks identify the respective services.

## Upstream MIT License

MIT License

Copyright (c) 2026 yetone

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
