# AIA Labels

[![Build](https://github.com/tarqd/aia-macos/actions/workflows/build.yml/badge.svg)](https://github.com/tarqd/aia-macos/actions/workflows/build.yml)

A macOS menu bar app for adding [AI Attribution (AIA)](https://timothyfcook.com/aia) labels to your writing.

- **Menu bar:** pick a label on the 3×3 grid (hover a square to preview it), then click the badge to copy it or drag it into a document.
- **Sizes:** click the bars under the badge, or scroll over the badge, to switch between text line, compact, medium, and full width.
- **Hotkey (⌃⌥A by default):** opens a floating picker. Type the ideas row (1–3), then the writing column (1–3), and press ↩. Focus stays in your document, so ⌘V pastes the label.
- **One copy, every format:** copying writes the HTML badge (`public.html`) and the Markdown badge (plain text) to the clipboard together. Rich editors paste the badge and plain-text editors paste Markdown.
- **Image instead:** hold ⌥ while clicking or dragging the badge (or press ⌥↩ in the picker) to use the PNG badge.

The app needs no special permissions and runs fully sandboxed.

## Install

Download `AIA-Labels.zip` from the [latest release](https://github.com/tarqd/aia-macos/releases/latest), unzip it, and move **AIA Labels** to Applications. Requires macOS 26.

Builds aren't notarized yet, so macOS blocks the first launch. Either right-click the app and choose **Open**, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/AIA Labels.app"
```

## Build

Requires Xcode 26 and [mise](https://mise.jdx.dev) (for XcodeGen).

```bash
mise exec -- xcodegen generate
xcodebuild -project AIALabels.xcodeproj -scheme AIALabels -derivedDataPath build build
open "build/Build/Products/Debug/AIA Labels.app"
```

Snippet generation lives in `Packages/AIAKit`, with tests that compare its output to the site's snippets character for character:

```bash
swift test --package-path Packages/AIAKit
```

CI builds every push and pull request. Pushing a `v*` tag publishes a release with the zipped app.

## Credits

Label definitions and artwork are by Timothy F. Cook and licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The bundled copy comes from the official [v1 label pack](https://timothyfcook.com/aia/v1/aia-labels-v1.zip).
