import Foundation

public struct AppSupport {
    public let directory: URL
    private let previousDirectories: [URL]

    public init(in applicationSupport: URL) {
        directory = applicationSupport.appendingPathComponent("meter", isDirectory: true)
        previousDirectories = ["Ration", "Yacht"].map {
            applicationSupport.appendingPathComponent($0, isDirectory: true)
        }
    }

    /// Claude profiles store the quoted script path. Keep recognizing it while
    /// the original executable exists, without editing those profiles on launch.
    public var previousTapCommands: [String] {
        previousDirectories.compactMap { directory in
            let script = TapDeployment.scriptURL(in: directory)
            guard FileManager.default.isExecutableFile(atPath: script.path) else { return nil }
            return TapDeployment.command(forScriptAt: script)
        }
    }

    /// Publish a complete copy on first launch. Later launches use meter's
    /// settings even if the user has since removed all their accounts.
    public func importPreviousInstallation() throws {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: directory.path) else { return }
        let files = ["config.json", "kimi-cache.json", "codex-cache.json", "grok-cache.json"]
        // Take one installation as a unit. Prefer the newest saved configuration,
        // and still recover cached readings if neither installation has a config.
        let configured = previousDirectories.first {
            fm.fileExists(atPath: $0.appendingPathComponent("config.json").path)
        }
        guard let previousDirectory = configured ?? previousDirectories.first(where: { candidate in
            files.contains { fm.fileExists(atPath: candidate.appendingPathComponent($0).path) }
        }) else { return }

        let staging = directory.deletingLastPathComponent()
            .appendingPathComponent(".meter-import-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: staging) }
        for name in files {
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
