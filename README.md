# AIA Labels

A macOS menu bar app for adding [AI Attribution (AIA)](https://timothyfcook.com/aia) labels to your writing.

- **Menu bar:** pick a label on the 3×3 grid, then click the badge to copy it or drag it into a document.
- **Hotkey (⌃⌥A by default):** opens a floating picker. Type the ideas row (1–3), then the words column (1–3), and press ↩. Focus stays in your document, so ⌘V pastes the label.
- **One copy, every format:** copying writes the HTML badge (`public.html`) and the Markdown badge (plain text) to the clipboard together. Rich editors paste the badge and plain-text editors paste Markdown. Use **Copy Image** (or ⇧↩ in the picker) when you want the PNG badge instead.

The app needs no special permissions and runs fully sandboxed.

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

## Credits

Label definitions and artwork are by Timothy F. Cook and licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The bundled copy comes from the official [v1 label pack](https://timothyfcook.com/aia/v1/aia-labels-v1.zip).
