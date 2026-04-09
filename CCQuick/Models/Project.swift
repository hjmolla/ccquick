import Foundation

struct Project: Codable, Identifiable, Hashable {
    var id: String { path }
    let path: String
    let name: String
    var lastOpened: Date?
    var openCount: Int
    var isPinned: Bool
    var isDiscovered: Bool
    var customIcon: String?  // SF Symbol name, nil = default

    init(path: String, lastOpened: Date? = nil, openCount: Int = 0, isPinned: Bool = false, isDiscovered: Bool = false, customIcon: String? = nil) {
        self.path = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
        self.lastOpened = lastOpened
        self.openCount = openCount
        self.isPinned = isPinned
        self.isDiscovered = isDiscovered
        self.customIcon = customIcon
    }

    // Support decoding from older JSON that lacks openCount
    enum CodingKeys: String, CodingKey {
        case path, name, lastOpened, openCount, isPinned, isDiscovered, customIcon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try container.decode(String.self, forKey: .path)
        self.name = try container.decode(String.self, forKey: .name)
        self.lastOpened = try container.decodeIfPresent(Date.self, forKey: .lastOpened)
        self.openCount = try container.decodeIfPresent(Int.self, forKey: .openCount) ?? 0
        self.isPinned = try container.decode(Bool.self, forKey: .isPinned)
        self.isDiscovered = try container.decode(Bool.self, forKey: .isDiscovered)
        self.customIcon = try container.decodeIfPresent(String.self, forKey: .customIcon)
    }

    var isGitRepo: Bool {
        FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git"))
    }

    var displayIcon: String {
        if let custom = customIcon { return custom }
        return "folder.fill"
    }
}
