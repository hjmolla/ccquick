import SwiftUI

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)

struct DirectoryRowView: View {
    let project: Project
    let isSelected: Bool
    var searchText: String = ""
    var onTogglePin: (() -> Void)? = nil
    var onChangeIcon: (() -> Void)? = nil
    var onLaunchWith: ((LaunchTarget) -> Void)? = nil
    @State private var isHovered: Bool = false
    @State private var iconHovered: Bool = false
    @State private var pinHovered: Bool = false
    @State private var conversationSummary: ConversationSummary? = nil
    @State private var showLaunchMenu: Bool = false
    @State private var gitStatus: GitStatus? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Project icon pill — click to change icon
            Button(action: { onChangeIcon?() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isSelected
                                ? Color.white.opacity(iconHovered ? 0.25 : 0.15)
                                : Color.primary.opacity(iconHovered ? 0.12 : (isHovered ? 0.08 : 0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isSelected
                                        ? Color.white.opacity(iconHovered ? 0.35 : 0.2)
                                        : Color.primary.opacity(iconHovered ? 0.15 : 0.08),
                                    lineWidth: 0.5
                                )
                        )
                        .frame(width: 32, height: 32)

                    ZStack {
                        Image(systemName: project.displayIcon)
                            .foregroundColor(isSelected ? .primary : .primary.opacity(0.7))
                            .font(.system(size: 14, weight: .medium))
                            .opacity(iconHovered ? 0.3 : 1)

                        if iconHovered {
                            Image(systemName: "pencil")
                                .foregroundColor(isSelected ? .primary : .primary.opacity(0.8))
                                .font(.system(size: 12, weight: .semibold))
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: iconHovered)
                }
            }
            .buttonStyle(.borderless)
            .onHover { h in iconHovered = h }

            VStack(alignment: .leading, spacing: 2) {
                highlightedName(project.name, query: searchText)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(isSelected ? .primary : .primary)
                    .lineLimit(1)

                if let summary = conversationSummary, isHovered || isSelected {
                    Text("\"\(summary.lastMessage)\"")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                        .lineLimit(1)
                        .italic()
                        .transition(.opacity)
                } else {
                    Text(abbreviatedPath(project.path))
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(isSelected ? .secondary.opacity(0.7) : .secondary)
                        .lineLimit(1)
                }

                if let git = gitStatus, (isHovered || isSelected) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 8))
                        Text(git.branch)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                        if git.changedFiles > 0 {
                            Text("\u{2022}")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("\(git.changedFiles) change\(git.changedFiles == 1 ? "" : "s")")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(claudeTerracotta)
                        }
                    }
                    .foregroundColor(.secondary.opacity(0.7))
                    .transition(.opacity)
                }
            }

            Spacer()

            if let date = project.lastOpened {
                Text(relativeDate(date))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(isSelected ? .secondary.opacity(0.6) : .secondary)
            }

            // Open with dropdown — appears on hover
            if isHovered || isSelected {
                Menu {
                    let installed = LaunchTarget.installed
                    ForEach(installed) { target in
                        Button(action: { onLaunchWith?(target) }) {
                            Label(target.rawValue, systemImage: target.icon)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isSelected ? .secondary.opacity(0.7) : .secondary)
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(isHovered && !isSelected ? 0.04 : 0))
                        )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 22)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            // Pin — appears on hover or if pinned
            if isHovered || isSelected || project.isPinned {
                Button(action: { onTogglePin?() }) {
                    Image(systemName: project.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(
                            pinHovered ? claudeTerracotta
                            : (project.isPinned ? claudeTerracotta : .secondary)
                        )
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(pinHovered ? claudeTerracotta.opacity(0.1) : Color.primary.opacity(0.04))
                        )
                        .scaleEffect(pinHovered ? 1.1 : 1.0)
                }
                .buttonStyle(.borderless)
                .onHover { h in
                    withAnimation(.easeInOut(duration: 0.12)) { pinHovered = h }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isSelected {
                    // Glass card
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                        )
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        .onAppear {
            DispatchQueue.global(qos: .utility).async {
                let summary = ConversationHistoryService.shared.getSummary(for: project.path)
                DispatchQueue.main.async {
                    conversationSummary = summary
                }
            }
            GitStatusService.shared.getStatus(for: project.path) { status in
                gitStatus = status
            }
        }
    }

    /// Highlights fuzzy-matched characters in the project name using the Claude terracotta color
    private func highlightedName(_ name: String, query: String) -> Text {
        guard !query.isEmpty else {
            return Text(name)
        }

        let lowerName = name.lowercased()
        let lowerQuery = query.lowercased()

        // Find fuzzy match indices
        var matchIndices: Set<String.Index> = []
        var searchIdx = lowerName.startIndex
        for ch in lowerQuery {
            if let found = lowerName[searchIdx...].firstIndex(of: ch) {
                // Map back to original name index
                let offset = lowerName.distance(from: lowerName.startIndex, to: found)
                let originalIdx = name.index(name.startIndex, offsetBy: offset)
                matchIndices.insert(originalIdx)
                searchIdx = lowerName.index(after: found)
            }
        }

        var result = Text("")
        for idx in name.indices {
            let char = String(name[idx])
            if matchIndices.contains(idx) {
                result = result + Text(char).foregroundColor(claudeTerracotta).bold()
            } else {
                result = result + Text(char)
            }
        }
        return result
    }

    private func abbreviatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
