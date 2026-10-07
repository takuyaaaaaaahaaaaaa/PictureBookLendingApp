// Standalone macOS 27 probe: demonstrate whether Core AI loads an existing Core ML package.
// Usage: swiftc CoreAIFormatProbe.swift -o /tmp/coreai-format-probe && /tmp/coreai-format-probe path
import CoreAI
import Foundation

@main struct CoreAIFormatProbe {
    static func main() async {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        do {
            let model = try await AIModel(contentsOf: url)
            print("loaded Core AI model; functions:", model.functionNames)
        } catch {
            print("Core AI load failed:", error)
        }
    }
}
