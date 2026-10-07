import AppKit
import Testing
@testable import AIAKit

/// Expected strings are copied verbatim from https://timothyfcook.com/aia.
@Suite struct SnippetsTests {
    let spec = AIASpec.bundled

    func snippets(_ code: String, _ size: BadgeSize = .wide, _ style: BadgeStyle = .color, _ format: ImageFormat = .svg) throws -> Snippets {
        let label = try #require(spec.label(code: code))
        return Snippets(label: label, options: .init(size: size, style: style, format: format), spec: spec)
    }

    @Test func bundledSpecHasFullGrid() {
        #expect(spec.codes.count == 9)
        for ideas in 1...3 {
            for words in 1...3 {
                #expect(spec.label(ideas: ideas, words: words) != nil)
            }
        }
        #expect(spec.label(code: "2x3")?.ideas == 2)
        #expect(spec.label(code: "2x3")?.words == 3)
    }

    @Test func wideHTML() throws {
        #expect(try snippets("1x2").html == #"<a href="https://timothyfcook.com/aia/1x2" rel="ai-attribution" title="AIA 1x2 · Polished: The ideas and the draft were human, but AI did copyedits and redrafting."><img src="https://timothyfcook.com/aia/v1/1x2/wide.svg" width="371" height="31" alt="AIA 1x2 · Polished: original ideas, some AI writing"></a>"#)
    }

    @Test func wideMarkdown() throws {
        #expect(try snippets("1x1").markdown == #"[![AIA 1x1 · No AI: original ideas and writing](https://timothyfcook.com/aia/v1/1x1/wide.svg)](https://timothyfcook.com/aia/1x1 "AIA 1x1 · No AI: A person's own ideas and writing. Spellcheck is allowed.")"#)
    }

    @Test func compactMonoSVGMarkdown() throws {
        #expect(try snippets("2x3", .compact, .mono).markdown == #"[![AIA 2x3 · Directed: some AI ideas, mostly AI writing](https://timothyfcook.com/aia/v1/2x3/compact-mono.svg)](https://timothyfcook.com/aia/2x3 "AIA 2x3 · Directed: Ideas shaped together, with AI writing most text under direction.")"#)
    }

    @Test func mediumPNGMarkdownFallsBackToHTML() throws {
        let expected = #"<a href="https://timothyfcook.com/aia/2x3" rel="ai-attribution" title="AIA 2x3 · Directed: Ideas shaped together, with AI writing most text under direction."><img src="https://timothyfcook.com/aia/v1/2x3/medium@2x.png" width="172" height="31" alt="AIA 2x3 · Directed: some AI ideas, mostly AI writing"></a>"#
        let s = try snippets("2x3", .medium, .color, .png)
        #expect(s.html == expected)
        #expect(s.markdown == expected)
    }

    @Test func textLineHTML() throws {
        #expect(try snippets("2x3", .textLine, .mono, .png).html == #"<p><a href="https://timothyfcook.com/aia/2x3" rel="ai-attribution" title="AIA 2x3 · Directed: Ideas shaped together, with AI writing most text under direction."><img src="https://timothyfcook.com/aia/v1/2x3/icon-mono.png" width="16" height="16" alt="" style="vertical-align:-3px"> <strong>AIA 2x3 · Directed.</strong></a> Some AI ideas, mostly AI writing.</p>"#)
        #expect(try snippets("2x3", .textLine).html.contains(#"src="https://timothyfcook.com/aia/v1/2x3/icon.svg""#))
    }

    @Test func textLineMarkdown() throws {
        #expect(try snippets("2x3", .textLine).markdown == #"**[AIA 2x3 · Directed.](https://timothyfcook.com/aia/2x3 "AIA 2x3 · Directed: Ideas shaped together, with AI writing most text under direction.")** Some AI ideas, mostly AI writing."#)
    }

    @Test func plainText() throws {
        #expect(try snippets("2x3").plainText == "AIA 2x3 · Directed. Some AI ideas, mostly AI writing. (timothyfcook.com/aia/2x3)")
    }

    @Test func pageHead() throws {
        #expect(try snippets("1x1").pageHead == """
        <meta name="ai-attribution" content="AIA 1x1">
        <link rel="ai-attribution" href="https://timothyfcook.com/aia/1x1">
        """)
    }

    @Test(arguments: [BadgeSize.wide, .medium, .compact])
    func everyBadgeHasArtwork(size: BadgeSize) {
        for label in spec.codes {
            let points = BadgeArtwork.pointSize(code: label.code, size: size)
            #expect(points.width > 0 && points.height > 0, "\(label.code) \(size)")
            for style in BadgeStyle.allCases {
                let image = BadgeArtwork.image(code: label.code, size: size, style: style)
                #expect(image?.size == NSSize(width: points.width, height: points.height), "\(label.code) \(size) \(style)")
            }
        }
    }

    @Test @MainActor func linkClipCarriesHTMLAndMarkdown() throws {
        let s = try snippets("1x2")
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        LabelClip.copy(s, as: .link, to: pasteboard)
        #expect(pasteboard.string(forType: .html) == s.html)
        #expect(pasteboard.string(forType: .string) == s.markdown)
    }

    @Test @MainActor func imageClipCarriesPNG() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        LabelClip.copy(try snippets("3x3", .medium), as: .image, to: pasteboard)
        #expect(pasteboard.data(forType: .png) != nil)
        #expect(pasteboard.data(forType: .tiff) != nil)
        #expect(pasteboard.string(forType: .string) == nil)
    }
}
