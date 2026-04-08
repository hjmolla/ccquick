import Foundation

struct ConversationSummary {
    let lastMessage: String
    let timestamp: Date
    let messageCount: Int
}

final class ConversationHistoryService: @unchecked Sendable {
    static let shared = ConversationHistoryService()
    private init() {}

    /// Get the last conversation summary for a project path
    func getSummary(for projectPath: String) -> ConversationSummary? {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")

        // Convert path to Claude's folder naming: replace / with -
        let folderName = projectPath.replacingOccurrences(of: "/", with: "-")
        let projectDir = claudeDir.appendingPathComponent(folderName)

        guard FileManager.default.fileExists(atPath: projectDir.path) else { return nil }

        // Find the most recent .jsonl file
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: projectDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }

        let jsonlFiles = files
            .filter { $0.pathExtension == "jsonl" }
            .sorted { a, b in
                let aDate = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let bDate = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return aDate > bDate
            }

        guard let latestFile = jsonlFiles.first else { return nil }

        // Read and parse
        guard let data = try? String(contentsOf: latestFile, encoding: .utf8) else { return nil }
        let lines = data.components(separatedBy: "\n").filter { !$0.isEmpty }

        var lastUserMessage: String? = nil
        var lastTimestamp: Date? = nil
        var messageCount = 0

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for line in lines {
            guard let jsonData = line.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { continue }

            let type = dict["type"] as? String
            let isMeta = dict["isMeta"] as? Bool ?? false

            guard type == "user", !isMeta else { continue }

            messageCount += 1

            // Extract text content
            guard let message = dict["message"] as? [String: Any],
                  let content = message["content"] else { continue }

            var text = ""
            if let contentStr = content as? String {
                text = contentStr
            } else if let contentArr = content as? [[String: Any]] {
                for item in contentArr {
                    if item["type"] as? String == "text",
                       let t = item["text"] as? String {
                        text = t
                        break
                    }
                }
            }

            // Skip system/command messages
            let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty && !clean.hasPrefix("<") && clean.count > 3 {
                lastUserMessage = clean
                if let ts = dict["timestamp"] as? String {
                    lastTimestamp = dateFormatter.date(from: ts)
                }
            }
        }

        guard let msg = lastUserMessage, let ts = lastTimestamp else { return nil }

        return ConversationSummary(
            lastMessage: String(msg.prefix(100)),
            timestamp: ts,
            messageCount: messageCount
        )
    }
}
