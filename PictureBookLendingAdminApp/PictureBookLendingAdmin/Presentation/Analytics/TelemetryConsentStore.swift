import Foundation

/// 書込完了/失敗を呼び出し側が確認できる、同意記録専用のストア。
@MainActor
protocol TelemetryConsentStore {
    func load() throws -> Data?
    func save(_ data: Data) throws
}

@MainActor
struct FileTelemetryConsentStore: TelemetryConsentStore {
    let url: URL
    
    init(url: URL? = nil) {
        self.url =
            url
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TelemetryConsent", isDirectory: true)
            .appendingPathComponent("consent.json")
    }
    
    func load() throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
    
    func save(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        let file = try FileHandle(forWritingTo: url)
        defer { try? file.close() }
        try file.synchronize()
    }
}
