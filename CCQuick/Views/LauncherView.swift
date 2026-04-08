import SwiftUI

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Glass search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 16, weight: .medium))

                TextField("Search projects...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .light, design: .rounded))
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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

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

            HStack(spacing: 10) {
                glassButton(icon: "folder.badge.plus", label: "Browse") {
                    viewModel.browseForDirectory()
                }

                glassButton(
                    icon: viewModel.isScanning ? "rays" : "arrow.clockwise",
                    label: viewModel.isScanning ? "Scanning..." : "Rescan"
                ) {
                    viewModel.scanForRepos()
                }
                .disabled(viewModel.isScanning)

                Spacer()

                HStack(spacing: 10) {
                    keyHint("⌘⇧C")
                    keyHint("⏎")
                    keyHint("↑↓")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

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

struct GlassBackground: View {
    static let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)
    static let claudeSand = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let claudeCream = Color(red: 0.99, green: 0.97, blue: 0.94)

    var body: some View {
        ZStack {
            // Base frosted glass
            GlassBlurView()

            // Warm tint
            LinearGradient(
                colors: [
                    GlassBackground.claudeTerracotta.opacity(0.04),
                    Color.clear,
                    GlassBackground.claudeSand.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Top edge rim light
            VStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.35),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.02)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                Spacer()
            }

            // Left edge rim
            HStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: 1)
                Spacer()
            }

            // Bottom inner shadow for depth
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03),
                            Color.white.opacity(0.08)
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
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
