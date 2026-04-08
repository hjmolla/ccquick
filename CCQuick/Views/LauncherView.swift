import SwiftUI
import Carbon
import CoreText

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search bar + action buttons
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search projects...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .italic()
                    .onSubmit {
                        viewModel.openProjectAtSelectedIndex()
                    }

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                            viewModel.searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.quaternary)
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.borderless)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                }

                // Action buttons in search bar area
                Divider()
                    .frame(height: 18)
                    .opacity(0.3)

                HStack(spacing: 6) {
                    BarIconButton(icon: "folder.badge.plus", tooltip: "Browse") {
                        viewModel.browseForDirectory()
                    }
                    BarIconButton(icon: "plus.rectangle", tooltip: "New Project") {
                        viewModel.createNewProject()
                    }
                    BarIconButton(
                        icon: viewModel.isScanning ? "rays" : "arrow.clockwise",
                        tooltip: "Rescan"
                    ) {
                        viewModel.scanForRepos()
                    }
                    .disabled(viewModel.isScanning)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Soft separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.primary.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            // Content area
            let allProjects = viewModel.allFilteredProjects
            let sections = viewModel.sections

            let activeSessions = viewModel.sessionTracker.sessions
            let hasContent = !allProjects.isEmpty || !activeSessions.isEmpty

            if !hasContent && !viewModel.searchText.isEmpty {
                emptySearchView
            } else if !hasContent {
                emptyStateView
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 2) {
                            // Active sessions
                            if !activeSessions.isEmpty && viewModel.searchText.isEmpty {
                                sectionHeader("Active Sessions", count: activeSessions.count, isFirst: true)

                                ForEach(Array(activeSessions.enumerated()), id: \.element.id) { sessionIdx, session in
                                    let sessionsForDir = activeSessions.filter { $0.directory == session.directory }
                                    let dirIdx = sessionsForDir.firstIndex(where: { $0.id == session.id }).map { $0 + 1 } ?? 1
                                    SessionRowView(
                                        session: session,
                                        sessionIndex: dirIdx,
                                        totalForProject: sessionsForDir.count,
                                        isSelected: sessionIdx == viewModel.selectedIndex,
                                        onTerminate: { viewModel.terminateSession(session) }
                                    )
                                    .id("s\(sessionIdx)")
                                    .onTapGesture {
                                        viewModel.selectedIndex = sessionIdx
                                        viewModel.focusSession(session)
                                    }
                                }
                            }

                            // Project sections
                            ForEach(Array(sections.enumerated()), id: \.element.title) { sectionIdx, section in
                                sectionHeader(
                                    section.title,
                                    count: section.projects.count,
                                    isFirst: sectionIdx == 0 && activeSessions.isEmpty
                                )

                                ForEach(section.projects) { project in
                                    let projectIdx = allProjects.firstIndex(where: { $0.id == project.id }) ?? 0
                                    let globalIdx = viewModel.projectStartIndex + projectIdx
                                    DirectoryRowView(
                                        project: project,
                                        isSelected: globalIdx == viewModel.selectedIndex,
                                        onTogglePin: { viewModel.togglePin(project) },
                                        onChangeIcon: { viewModel.showIconPicker(for: project) },
                                        onLaunchWith: { target in viewModel.openProject(project, with: target) }
                                    )
                                    .id("p\(globalIdx)")
                                    .onTapGesture {
                                        viewModel.selectedIndex = globalIdx
                                        viewModel.openProject(project)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .onChange(of: viewModel.selectedIndex) { newIndex in
                        let sessions = viewModel.searchText.isEmpty ? viewModel.sessionTracker.sessions : []
                        let scrollId: String = newIndex < sessions.count ? "s\(newIndex)" : "p\(newIndex)"
                        proxy.scrollTo(scrollId, anchor: .center)
                    }
                }
            }

            // Glass bottom bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.primary.opacity(0.06), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            // Claude not installed warning
            if !viewModel.isClaudeInstalled {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 11))
                    Text("Claude Code not found")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.orange)
                    Spacer()
                    Button(action: { viewModel.installClaude() }) {
                        Text("Install")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange))
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.06))
            }

            // Bottom bar — shortcuts only
            HStack(spacing: 16) {
                Spacer()
                keyCombo(label: "Open", keys: ["⏎"])
                keyCombo(label: "Navigate", keys: ["↑", "↓"])
                keyCombo(label: "Toggle", keys: shortcutKeysArray())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)

        }
        .frame(width: 560, height: 460)
        .background(GlassBackground())
        .overlay {
            if let project = viewModel.iconPickerProject {
                ZStack {
                    // Dim the launcher content behind the picker
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .onTapGesture { viewModel.iconPickerProject = nil }

                    IconPickerView(
                        currentIcon: project.displayIcon,
                        onSelect: { icon in
                            viewModel.setIcon(project, icon: icon)
                            viewModel.iconPickerProject = nil
                        },
                        onCancel: { viewModel.iconPickerProject = nil }
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 16, y: 4)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: viewModel.iconPickerProject != nil)
            }
        }
        .onAppear {
            registerDMSerifFont()
            viewModel.scanForRepos()
        }
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String, count: Int, isFirst: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: sectionIcon(title))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)

            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)

            Text("\(count)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.04))
                )
        }
        .padding(.horizontal, 14)
        .padding(.top, isFirst ? 8 : 16)
        .padding(.bottom, 4)
    }

    private var emptySearchView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primary.opacity(0.06), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.tertiary)
            }
            Text("No results for \"\(viewModel.searchText)\"")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primary.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 44
                        )
                    )
                    .frame(width: 88, height: 88)

                AppLogoView(size: 40)
                    .opacity(0.35)
            }
            Text("No projects yet")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text("Browse for a directory or scan for repos")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func glassButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            .foregroundColor(.primary.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.primary.opacity(0.06))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.borderless)
    }

    private func keyCombo(label: String, keys: [String]) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.5))
                        .frame(minWidth: 20, minHeight: 18)
                        .padding(.horizontal, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                }
            }
        }
    }

    private func shortcutKeysArray() -> [String] {
        let s = Preferences.shared.shortcut
        var keys: [String] = []
        if s.modifiers & UInt32(cmdKey) != 0 { keys.append("⌘") }
        if s.modifiers & UInt32(shiftKey) != 0 { keys.append("⇧") }
        if s.modifiers & UInt32(optionKey) != 0 { keys.append("⌥") }
        if s.modifiers & UInt32(controlKey) != 0 { keys.append("⌃") }
        let keyNames: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P",
            37: "L", 38: "J", 40: "K", 45: "N", 46: "M", 49: "Space"
        ]
        keys.append(keyNames[s.keyCode] ?? "?")
        return keys
    }

    private func registerDMSerifFont() {
        guard let fontPath = Bundle.main.path(forResource: "DMSerifDisplay-Italic", ofType: "ttf"),
              let fontData = NSData(contentsOfFile: fontPath),
              let provider = CGDataProvider(data: fontData),
              let cgFont = CGFont(provider) else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(cgFont, &error)
    }

    private func keyHint(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundColor(.primary.opacity(0.35))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )
    }

    private func sectionIcon(_ title: String) -> String {
        switch title {
        case "Active Sessions": return "bolt.fill"
        case "Pinned": return "pin.fill"
        case "Recent": return "clock"
        case "Discovered": return "arrow.triangle.branch"
        default: return "magnifyingglass"
        }
    }
}

// MARK: - Glass Background

struct BarIconButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isHovered ? .primary.opacity(0.8) : .primary.opacity(0.45))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .opacity(isHovered ? 1 : 0.5)
                        .shadow(color: Color.black.opacity(isHovered ? 0.1 : 0.04), radius: isHovered ? 4 : 2, y: 1)
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(isHovered ? 0.3 : 0.15), Color.white.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.borderless)
        .onHover { h in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isHovered = h }
        }
        .overlay(alignment: .bottom) {
            if isHovered {
                Text(tooltip)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    )
                    .offset(y: 32)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

struct GlassBackground: View {
    static let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)
    static let claudeSand = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let claudeCream = Color(red: 0.99, green: 0.97, blue: 0.94)

    var body: some View {
        ZStack {
            // Base frosted glass — strong blur, see-through
            GlassBlurView()

            // Top edge rim light
            VStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.5)
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
}

struct AppLogoView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let path = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "terminal")
                    .font(.system(size: size * 0.7, weight: .light))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct GlassBlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
