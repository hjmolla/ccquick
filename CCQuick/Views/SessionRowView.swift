import SwiftUI

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)

struct SessionRowView: View {
    let session: ClaudeSession
    var sessionIndex: Int = 1   // 1-based, shows "#2" etc when > 1
    var totalForProject: Int = 1
    var isSelected: Bool = false
    var onTerminate: (() -> Void)? = nil
    @State private var isHovered: Bool = false
    @State private var isPulsing: Bool = false
    @State private var showTerminateConfirm: Bool = false
    @State private var xHovered: Bool = false

    var body: some View {
        if showTerminateConfirm {
            // Inline confirmation row
            HStack(spacing: 10) {
                Text("End \(session.projectName)?")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(1)

                Spacer()

                Button("Cancel") {
                    withAnimation(.easeOut(duration: 0.15)) {
                        showTerminateConfirm = false
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary)

                Button(action: {
                    showTerminateConfirm = false
                    onTerminate?()
                }) {
                    Text("End")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.red))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.15), lineWidth: 0.5)
                    )
            )
            .transition(.opacity)
        } else {

        HStack(spacing: 12) {
            // Pulsing live indicator
            ZStack {
                // Pulse ring
                Circle()
                    .stroke(Color.green.opacity(isPulsing ? 0 : 0.3), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isPulsing ? 1.4 : 1.0)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.green.opacity(isHovered ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.green.opacity(0.2), lineWidth: 0.5)
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 13, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.projectName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Show session number when multiple for same project
                    if totalForProject > 1 {
                        Text("#\(sessionIndex)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.5))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }

                    // Live pill
                    Text("LIVE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.12))
                        )
                }

                Text(abbreviatedPath(session.directory))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Duration
            Text(session.duration)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            // Terminate button — appears on hover
            if isHovered || isSelected {
                Button(action: { showTerminateConfirm = true }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(xHovered ? .red : .secondary.opacity(0.6))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(xHovered ? Color.red.opacity(0.1) : Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.borderless)
                .onHover { h in
                    withAnimation(.easeInOut(duration: 0.12)) { xHovered = h }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHovered ? Color.green.opacity(0.04) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(isHovered ? Color.green.opacity(0.1) : Color.clear, lineWidth: 0.5)
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
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }

        } // end else (not confirming)
    }

    private func abbreviatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

