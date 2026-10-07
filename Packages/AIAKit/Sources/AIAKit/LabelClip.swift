import AppKit
import UniformTypeIdentifiers

/// What a copy or drag puts on the pasteboard.
public enum ClipKind: String, CaseIterable, Codable, Sendable {
    /// HTML badge for rich editors, with the Markdown snippet as the plain-text flavor.
    case link
    /// The badge PNG, for apps that only take images.
    case image
    /// The plain-text sentence only, for chat apps.
    case plainText
}

/// Writes labels to the clipboard or a drag session. Every flavor goes on at once and
/// the receiving app picks the richest one it understands.
@MainActor
public enum LabelClip {
    public static func copy(_ snippets: Snippets, as kind: ClipKind, to pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()
        pasteboard.writeObjects([pasteboardItem(snippets, as: kind)])
    }

    public static func pasteboardItem(_ snippets: Snippets, as kind: ClipKind) -> NSPasteboardItem {
        let item = NSPasteboardItem()
        switch kind {
        case .link:
            item.setString(snippets.html, forType: .html)
            item.setString(snippets.markdown, forType: .string)
        case .image:
            let label = snippets.label.code, options = snippets.options
            if let png = BadgeArtwork.pngData(code: label, size: options.size, style: options.style) {
                item.setData(png, forType: .png)
            }
            if let tiff = BadgeArtwork.image(code: label, size: options.size, style: options.style)?.tiffRepresentation {
                item.setData(tiff, forType: .tiff)
            }
        case .plainText:
            item.setString(snippets.plainText, forType: .string)
        }
        return item
    }

    public static func itemProvider(_ snippets: Snippets, as kind: ClipKind) -> NSItemProvider {
        let provider = NSItemProvider()
        switch kind {
        case .link:
            register(snippets.html, as: .html, in: provider)
            register(snippets.markdown, as: .utf8PlainText, in: provider)
        case .image:
            let label = snippets.label.code, options = snippets.options
            if let png = BadgeArtwork.pngData(code: label, size: options.size, style: options.style) {
                provider.registerDataRepresentation(for: .png) { completion in
                    completion(png, nil)
                    return nil
                }
                provider.suggestedName = "AIA \(label)"
            }
        case .plainText:
            register(snippets.plainText, as: .utf8PlainText, in: provider)
        }
        return provider
    }

    private static func register(_ string: String, as type: UTType, in provider: NSItemProvider) {
        let data = Data(string.utf8)
        provider.registerDataRepresentation(for: type) { completion in
            completion(data, nil)
            return nil
        }
    }
}
