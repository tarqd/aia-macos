import Foundation

/// The AIA spec as published at https://timothyfcook.com/aia/v1/spec.json.
public struct AIASpec: Decodable, Sendable {
    public struct License: Decodable, Sendable {
        public let name: String
        public let url: URL
    }

    public struct Axes: Decodable, Sendable {
        public let ideas: [String]
        public let words: [String]
    }

    public let name: String
    public let version: String
    public let site: URL
    public let license: License
    public let axes: Axes
    public let codes: [AIALabel]
}

/// One cell of the 3×3 grid, e.g. `1x2 · Polished`.
public struct AIALabel: Decodable, Sendable, Hashable, Identifiable {
    /// `"{ideas}x{words}"`, each 1–3.
    public let code: String
    public let name: String
    public let summary: String
    public let description: String
    public let color: String
    public let tint: String
    public let dark: String

    public var id: String { code }

    /// Row on the "Where did the ideas come from?" axis (1 = original, 3 = mostly AI).
    public var ideas: Int { axisValue(at: 0) }
    /// Column on the "Who wrote the words?" axis (1 = original, 3 = mostly AI).
    public var words: Int { axisValue(at: 1) }

    private func axisValue(at index: Int) -> Int {
        let parts = code.split(separator: "x")
        guard parts.count == 2, let value = Int(parts[index]) else { return 0 }
        return value
    }
}

extension AIASpec {
    /// The copy of the spec and label artwork bundled with the app.
    public static let bundled: AIASpec = {
        guard let url = Bundle.module.url(forResource: "spec", withExtension: "json", subdirectory: "aia-v1"),
              let data = try? Data(contentsOf: url),
              let spec = try? JSONDecoder().decode(AIASpec.self, from: data)
        else { fatalError("Bundled AIA spec is missing or invalid") }
        return spec
    }()

    public func label(code: String) -> AIALabel? {
        codes.first { $0.code == code }
    }

    public func label(ideas: Int, words: Int) -> AIALabel? {
        label(code: "\(ideas)x\(words)")
    }
}
