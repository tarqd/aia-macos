import AppKit
import Synchronization

/// Locates the label artwork bundled with the app (a copy of the official v1 ZIP).
public enum BadgeArtwork {
    public struct PointSize: Hashable, Sendable {
        public let width: Int
        public let height: Int
    }

    /// e.g. `wide.svg`, `medium-mono@2x.png`. Text lines use the wide badge.
    static func fileName(size: BadgeSize, style: BadgeStyle, format: ImageFormat) -> String {
        let base = (size == .textLine ? BadgeSize.wide : size).rawValue + (style == .mono ? "-mono" : "")
        return format == .svg ? "\(base).svg" : "\(base)@2x.png"
    }

    /// e.g. `icon.svg`, `icon-mono.png` (the site serves the 64px icon without an `@2x` suffix).
    static func iconFileName(style: BadgeStyle, format: ImageFormat) -> String {
        "icon" + (style == .mono ? "-mono" : "") + ".\(format.rawValue)"
    }

    /// The badge's size in points, read from the `width`/`height` of its SVG.
    public static func pointSize(code: String, size: BadgeSize) -> PointSize {
        let key = "\(code)/\(size.rawValue)"
        return pointSizeCache.withLock { cache in
            if let cached = cache[key] { return cached }
            let measured = measure(code: code, size: size)
            cache[key] = measured
            return measured
        }
    }

    /// The retina PNG for a badge, sized in points so it pastes at its natural size.
    public static func image(code: String, size: BadgeSize, style: BadgeStyle) -> NSImage? {
        let name = fileName(size: size, style: style, format: .png)
        guard let url = localURL(code: code, file: name), let image = NSImage(contentsOf: url) else { return nil }
        let points = pointSize(code: code, size: size)
        image.size = NSSize(width: points.width, height: points.height)
        for rep in image.representations {
            rep.size = image.size
        }
        return image
    }

    /// The small grid icon used by text-line labels.
    public static func icon(code: String, style: BadgeStyle) -> NSImage? {
        localURL(code: code, file: iconFileName(style: style, format: .png)).flatMap(NSImage.init(contentsOf:))
    }

    public static func pngData(code: String, size: BadgeSize, style: BadgeStyle) -> Data? {
        localURL(code: code, file: fileName(size: size, style: style, format: .png)).flatMap { try? Data(contentsOf: $0) }
    }

    static func localURL(code: String, file: String) -> URL? {
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        return Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "aia-v1/\(code)")
    }

    private static let pointSizeCache = Mutex<[String: PointSize]>([:])

    private static func measure(code: String, size: BadgeSize) -> PointSize {
        guard let url = localURL(code: code, file: fileName(size: size, style: .color, format: .svg)),
              let svg = try? String(contentsOf: url, encoding: .utf8),
              let match = svg.firstMatch(of: /<svg[^>]*\swidth="(\d+)"\s+height="(\d+)"/),
              let width = Int(match.1), let height = Int(match.2)
        else { return PointSize(width: 0, height: 0) }
        return PointSize(width: width, height: height)
    }
}
