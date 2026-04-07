import Foundation
import Cocoa

enum LaunchTarget: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm2 = "iTerm2"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .terminal: return "terminal"
        case .iterm2: return "rectangle.topthird.inset.filled"
        }
    }

    var isInstalled: Bool {
        switch self {
        case .terminal: return true
        case .iterm2:
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return FileManager.default.fileExists(atPath: "/Applications/iTerm.app") ||
                   FileManager.default.fileExists(atPath: home + "/Applications/iTerm.app")
        }
    }

    static var installed: [LaunchTarget] {
        allCases.filter(\.isInstalled)
    }
}

final class TerminalLaunchService: @unchecked Sendable {
    static let shared = TerminalLaunchService()
    private init() {}

    /// Launch with default terminal from Preferences
    func launchClaude(in directory: String) {
        let target: LaunchTarget
        switch Preferences.shared.terminalType {
        case .terminal: target = .terminal
        case .iterm2: target = .iterm2
        case .warp: target = .terminal // fallback to Terminal
        }
        launchClaude(in: directory, with: target)
    }

    /// Launch with a specific target
    func launchClaude(in directory: String, with target: LaunchTarget) {
        let escapedPath = directory
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let claudePath = Preferences.shared.claudePath

        switch target {
        case .terminal:
            runAppleScript("""
            tell application "Terminal"
                do script "cd \\"\(escapedPath)\\" && \(claudePath)"
                activate
            end tell
            """)
        case .iterm2:
            runAppleScript("""
            tell application "iTerm"
                activate
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text "cd \\"\(escapedPath)\\" && \(claudePath)"
                end tell
            end tell
            """)
        }
    }

    private func runAppleScript(_ source: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(&error)
                if let error = error {
                    print("[CCQuick] AppleScript error: \(error)")
                }
            }
        }
    }

    private func runShell(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", command]
            try? process.run()
        }
    }
}
