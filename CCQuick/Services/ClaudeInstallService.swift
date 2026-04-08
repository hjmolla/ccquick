import Foundation
import Cocoa

final class ClaudeInstallService: @unchecked Sendable {
    static let shared = ClaudeInstallService()
    private init() {}

    var isInstalled: Bool {
        let path = Preferences.shared.claudePath
        return FileManager.default.fileExists(atPath: path)
    }

    /// Try common paths
    func detectPath() -> String? {
        let paths = [
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "/usr/bin/claude"
        ]
        for p in paths {
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        // Try which
        return Preferences.shared.detectClaudePath()
    }

    func installViaBrew() {
        let script = """
        tell application "Terminal"
            do script "npm install -g @anthropic-ai/claude-code"
            activate
        end tell
        """
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
}
