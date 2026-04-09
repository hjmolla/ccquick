import Foundation

struct GitStatus {
    let branch: String
    let changedFiles: Int
}

final class GitStatusService: @unchecked Sendable {
    static let shared = GitStatusService()

    private var cache: [String: (status: GitStatus, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 30  // cache for 30 seconds
    private let queue = DispatchQueue(label: "com.ccquick.gitstatus", attributes: .concurrent)

    private init() {}

    /// Get cached git status or fetch fresh. Calls completion on main thread.
    func getStatus(for path: String, completion: @escaping (GitStatus?) -> Void) {
        // Check if .git exists
        let gitDir = (path as NSString).appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir) else {
            completion(nil)
            return
        }

        // Check cache
        queue.sync {
            if let cached = cache[path], Date().timeIntervalSince(cached.timestamp) < cacheDuration {
                completion(cached.status)
                return
            }
        }

        // Fetch in background
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let branch = self?.runGit(["git", "-C", path, "branch", "--show-current"]) ?? ""
            let porcelain = self?.runGit(["git", "-C", path, "status", "--porcelain"]) ?? ""
            let changedCount = porcelain.isEmpty ? 0 : porcelain.components(separatedBy: "\n").filter { !$0.isEmpty }.count

            let branchName = branch.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !branchName.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let status = GitStatus(branch: branchName, changedFiles: changedCount)

            self?.queue.async(flags: .barrier) {
                self?.cache[path] = (status: status, timestamp: Date())
            }

            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    /// Invalidate cache for a specific path
    func invalidate(path: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: path)
        }
    }

    private func runGit(_ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
