import Foundation

/// The badge sizes offered on the AIA site.
public enum BadgeSize: String, CaseIterable, Codable, Sendable {
    case wide
    case medium
    case compact
    /// A one-line text label with a small icon instead of a badge.
    case textLine

    public var displayName: String {
        switch self {
        case .wide: "Full width"
        case .medium: "Medium"
        case .compact: "Compact"
        case .textLine: "Text line"
        }
    }
}

public enum BadgeStyle: String, CaseIterable, Codable, Sendable {
    case color
    case mono

    public var displayName: String {
        switch self {
        case .color: "Color"
        case .mono: "Mono"
        }
    }
}

/// Which hosted artwork the HTML and Markdown snippets point at.
public enum ImageFormat: String, CaseIterable, Codable, Sendable {
    case svg
    case png

    public var displayName: String { rawValue.uppercased() }
}

public struct SnippetOptions: Hashable, Codable, Sendable {
    public var size: BadgeSize
    public var style: BadgeStyle
    public var format: ImageFormat

    public init(size: BadgeSize = .wide, style: BadgeStyle = .color, format: ImageFormat = .svg) {
        self.size = size
        self.style = style
        self.format = format
    }
}

/// Builds the same snippets the AIA site offers, character for character.
public struct Snippets: Sendable {
    public let label: AIALabel
    public let options: SnippetOptions
    private let spec: AIASpec

    public init(label: AIALabel, options: SnippetOptions = .init(), spec: AIASpec = .bundled) {
        self.label = label
        self.options = options
        self.spec = spec
    }

    // MARK: Snippets

    public var html: String {
        if options.size == .textLine {
            return #"<p><a href="\#(pageURL)" rel="ai-attribution" title="\#(escape(title))"><img src="\#(iconURL)" width="16" height="16" alt="" style="vertical-align:-3px"> <strong>\#(escape(heading)).</strong></a> \#(escape(label.summary))</p>"#
        }
        let size = BadgeArtwork.pointSize(code: label.code, size: options.size)
        return #"<a href="\#(pageURL)" rel="ai-attribution" title="\#(escape(title))"><img src="\#(badgeURL)" width="\#(size.width)" height="\#(size.height)" alt="\#(escape(alt))"></a>"#
    }

    public var markdown: String {
        switch (options.size, options.format) {
        case (.textLine, _):
            #"**[\#(heading).](\#(pageURL) "\#(title)")** \#(label.summary)"#
        case (_, .svg):
            #"[![\#(alt)](\#(badgeURL))](\#(pageURL) "\#(title)")"#
        case (_, .png):
            // Matches the site, which falls back to HTML (valid in Markdown) for retina PNGs.
            html
        }
    }

    public var plainText: String {
        "\(heading). \(label.summary) (\(pageURL.trimmingPrefix("https://")))"
    }

    public var pageHead: String {
        """
        <meta name="ai-attribution" content="AIA \(label.code)">
        <link rel="ai-attribution" href="\(pageURL)">
        """
    }

    // MARK: Pieces

    /// `AIA 1x2 · Polished`
    public var heading: String { "AIA \(label.code) · \(label.name)" }

    /// `AIA 1x2 · Polished: The ideas and the draft were human, …`
    public var title: String { "\(heading): \(label.description)" }

    /// `AIA 1x2 · Polished: original ideas, some AI writing`
    public var alt: String {
        var summary = label.summary
        if summary.hasSuffix(".") { summary.removeLast() }
        return "\(heading): \(summary.prefix(1).lowercased())\(summary.dropFirst())"
    }

    public var pageURL: String {
        "\(siteRoot)/aia/\(label.code)"
    }

    var badgeURL: String {
        "\(assetRoot)/\(BadgeArtwork.fileName(size: options.size, style: options.style, format: options.format))"
    }

    var iconURL: String {
        "\(assetRoot)/\(BadgeArtwork.iconFileName(style: options.style, format: options.format))"
    }

    private var siteRoot: String {
        spec.site.absoluteString.trimmingSuffix("/")
    }

    private var assetRoot: String {
        "\(siteRoot)/aia/\(spec.version)/\(label.code)"
    }

    private func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}
