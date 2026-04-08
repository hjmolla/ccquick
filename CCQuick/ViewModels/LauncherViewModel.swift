import Foundation
import Cocoa
import SwiftUI
import Combine

final class LauncherViewModel: ObservableObject, @unchecked Sendable {
    @Published var searchText: String = ""
    @Published var selectedIndex: Int = 0
    @Published var isScanning: Bool = false
    @Published var iconPickerProject: Project? = nil
    @Published var panelVisible: Bool = false

    let store: ProjectStore
    let sessionTracker: SessionTracker
    private let terminalService = TerminalLaunchService.shared
    private let discoveryService = GitDiscoveryService()
    private var sessionCancellable: AnyCancellable?

    var onDismiss: (() -> Void)?

    init(store: ProjectStore, sessionTracker: SessionTracker) {
        self.store = store
        self.sessionTracker = sessionTracker
        // Re-publish session changes
        sessionCancellable = sessionTracker.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }

    /// All projects in display order: pinned, recent, discovered — filtered by search
    var allFilteredProjects: [Project] {
        let pinned = store.pinnedProjects
        let recent = store.recentProjects
        let discovered = store.discoveredProjects
        let all = pinned + recent + discovered

        if searchText.isEmpty { return all }

        let query = searchText.lowercased()
        return all.filter {
            fuzzyMatch(query: query, target: $0.name.lowercased()) ||
            fuzzyMatch(query: query, target: $0.path.lowercased())
        }
    }

    /// Section labels and ranges for the current filtered list
    var sections: [(title: String, projects: [Project])] {
        if !searchText.isEmpty {
            let results = allFilteredProjects
            return results.isEmpty ? [] : [("Results", results)]
        }
        var s: [(String, [Project])] = []
        let pinned = store.pinnedProjects
        let recent = store.recentProjects
        let discovered = store.discoveredProjects
        if !pinned.isEmpty { s.append(("Pinned", pinned)) }
        if !recent.isEmpty { s.append(("Recent", recent)) }
        if !discovered.isEmpty { s.append(("Discovered", discovered)) }
        return s
    }

    func openProject(_ project: Project) {
        store.recordOpen(path: project.path)
        onDismiss?()
        terminalService.launchClaude(in: project.path)
    }

    func openProject(_ project: Project, with target: LaunchTarget) {
        store.recordOpen(path: project.path)
        onDismiss?()
        terminalService.launchClaude(in: project.path, with: target)
    }

    var totalItemCount: Int {
        let sessionCount = searchText.isEmpty ? sessionTracker.sessions.count : 0
        return sessionCount + allFilteredProjects.count
    }

    var projectStartIndex: Int {
        searchText.isEmpty ? sessionTracker.sessions.count : 0
    }

    func openProjectAtSelectedIndex() {
        let sessions = searchText.isEmpty ? sessionTracker.sessions : []
        if selectedIndex < sessions.count {
            focusSession(sessions[selectedIndex])
            return
        }
        let projectIdx = selectedIndex - sessions.count
        let projects = allFilteredProjects
        guard !projects.isEmpty, projectIdx >= 0, projectIdx < projects.count else { return }
        openProject(projects[projectIdx])
    }

    func togglePin(_ project: Project) {
        store.togglePin(path: project.path)
    }

    func setIcon(_ project: Project, icon: String?) {
        store.setIcon(path: project.path, icon: icon)
    }

    func showIconPicker(for project: Project) {
        iconPickerProject = project
    }

    func focusSession(_ session: ClaudeSession) {
        onDismiss?()
        sessionTracker.focusSession(session)
    }

    func terminateSession(_ session: ClaudeSession) {
        sessionTracker.terminateSession(session)
    }

    func browseForDirectory() {
        onDismiss?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.message = "Select a project directory to open with Claude"
            panel.prompt = "Open with Claude"

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                let path = url.path
                self?.store.recordOpen(path: path)
                self?.terminalService.launchClaude(in: path)
            }
        }
    }

    var isClaudeInstalled: Bool {
        ClaudeInstallService.shared.isInstalled
    }

    func createNewProject() {
        onDismiss?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let panel = NSSavePanel()
            panel.title = "Create New Project"
            panel.prompt = "Create"
            panel.nameFieldLabel = "Project Name:"
            panel.nameFieldStringValue = "my-project"
            panel.canCreateDirectories = true

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                // Create the directory
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                let path = url.path
                self?.store.recordOpen(path: path)
                self?.terminalService.launchClaude(in: path)
            }
        }
    }

    func installClaude() {
        ClaudeInstallService.shared.installViaBrew()
    }

    func scanForRepos() {
        isScanning = true
        discoveryService.discover { [weak self] paths in
            self?.store.addDiscoveredRepos(paths)
            self?.isScanning = false
        }
    }

    func moveSelectionUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    func moveSelectionDown() {
        if selectedIndex < totalItemCount - 1 { selectedIndex += 1 }
    }

    func resetSelection() {
        selectedIndex = 0
    }

    // Simple fuzzy match: all characters of query appear in order in target
    private func fuzzyMatch(query: String, target: String) -> Bool {
        var targetIdx = target.startIndex
        for ch in query {
            guard let found = target[targetIdx...].firstIndex(of: ch) else { return false }
            targetIdx = target.index(after: found)
        }
        return true
    }
}
