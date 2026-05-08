import Foundation

enum ClaudeModel: String, CaseIterable, Identifiable, Codable {
    case defaultModel = ""
    case opus = "claude-opus-4-6"
    case sonnet = "claude-sonnet-4-6"
    case haiku = "claude-haiku-4-5-20251001"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .defaultModel: return "Default"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        case .haiku: return "Haiku"
        }
    }

    var shortName: String {
        switch self {
        case .defaultModel: return "Default"
        case .opus: return "Opus"
        case .sonnet: return "Sonnet"
        case .haiku: return "Haiku"
        }
    }
}

struct ClaudeLaunchOptions: Codable, Equatable {
    var skipPermissions: Bool = false
    var continueSession: Bool = false
    var resumeSessionId: String = ""
    var model: ClaudeModel = .defaultModel
    var verbose: Bool = false
    var maxTurns: Int? = nil
    var systemPrompt: String = ""
    var allowedTools: String = ""

    static let `default` = ClaudeLaunchOptions()

    /// Build the CLI arguments string from the current options
    func buildArgs() -> String {
        var args: [String] = []

        if skipPermissions {
            args.append("--dangerously-skip-permissions")
        }
        if continueSession {
            args.append("--continue")
        }
        if !resumeSessionId.isEmpty {
            args.append("--resume \"\(resumeSessionId)\"")
        }
        if model != .defaultModel {
            args.append("--model \(model.rawValue)")
        }
        if verbose {
            args.append("--verbose")
        }
        if let turns = maxTurns, turns > 0 {
            args.append("--max-turns \(turns)")
        }
        if !systemPrompt.isEmpty {
            let escaped = systemPrompt
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            args.append("--system-prompt \"\(escaped)\"")
        }
        if !allowedTools.isEmpty {
            args.append("--allowedTools \"\(allowedTools)\"")
        }

        return args.joined(separator: " ")
    }

    /// Whether any option is set (non-default)
    var hasActiveOptions: Bool {
        self != .default
    }

    /// Count of active options for badge display
    var activeCount: Int {
        var count = 0
        if skipPermissions { count += 1 }
        if continueSession { count += 1 }
        if !resumeSessionId.isEmpty { count += 1 }
        if model != .defaultModel { count += 1 }
        if verbose { count += 1 }
        if maxTurns != nil { count += 1 }
        if !systemPrompt.isEmpty { count += 1 }
        if !allowedTools.isEmpty { count += 1 }
        return count
    }
}
