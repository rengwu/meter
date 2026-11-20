import Foundation

public struct AppSupport {
    public let directory: URL
    private let previousDirectory: URL

    public init(in applicationSupport: URL) {
        directory = applicationSupport.appendingPathComponent("Ration", isDirectory: true)
        previousDirectory = applicationSupport.appendingPathComponent("Yacht", isDirectory: true)
    }

    /// Claude profiles store the quoted script path. Keep recognizing it while
    /// the original executable exists, without editing those profiles on launch.
    public var previousTapCommand: String? {
        let script = TapDeployment.scriptURL(in: previousDirectory)
        guard FileManager.default.isExecutableFile(atPath: script.path) else { return nil }
        return TapDeployment.command(forScriptAt: script)
    }

    /// Publish a complete copy on first launch. Later launches use Ration's
    /// settings even if the user has since removed all their accounts.
    public func importPreviousInstallation() throws {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: directory.path),
              fm.fileExists(atPath: previousDirectory.path) else { return }

        let staging = directory.deletingLastPathComponent()
            .appendingPathComponent(".ration-import-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: staging) }
        for name in ["config.json", "kimi-cache.json", "codex-cache.json", "grok-cache.json"] {
            let source = previousDirectory.appendingPathComponent(name)
            if fm.fileExists(atPath: source.path) {
                try fm.copyItem(at: source, to: staging.appendingPathComponent(name))
            }
        }
        do {
            try fm.moveItem(at: staging, to: directory)
        } catch CocoaError.fileWriteFileExists {
            // Another launch finished the import first.
        }
    }
}
