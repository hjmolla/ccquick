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
    @State private var conversationSummary: ConversationSummary? = nil

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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.red.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
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
                    .stroke(claudeTerracotta.opacity(isPulsing ? 0 : 0.3), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isPulsing ? 1.4 : 1.0)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(claudeTerracotta.opacity(isHovered ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(claudeTerracotta.opacity(0.2), lineWidth: 0.5)
                    )
                    .frame(width: 32, height: 32)

                ClaudeLogoView(size: 20, seed: Int(session.id))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.projectName)
                        .font(.system(size: 13, weight: .regular, design: .serif))
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
                        .foregroundColor(claudeTerracotta)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(claudeTerracotta.opacity(0.12))
                        )
                }

                if let summary = conversationSummary, isHovered || isSelected {
                    Text("\"\(summary.lastMessage)\"")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                        .lineLimit(1)
                        .italic()
                        .transition(.opacity)
                } else {
                    Text(abbreviatedPath(session.directory))
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 1)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isHovered ? claudeTerracotta.opacity(0.04) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isHovered ? claudeTerracotta.opacity(0.1) : Color.clear, lineWidth: 0.5)
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
            DispatchQueue.global(qos: .utility).async {
                let summary = ConversationHistoryService.shared.getSummary(for: session.directory)
                DispatchQueue.main.async {
                    conversationSummary = summary
                }
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

struct ClaudeLogoView: View {
    let size: CGFloat
    var seed: Int = 0  // different seed = different timing
    @State private var floatOffset: CGFloat = 0
    @State private var tilt: Double = 0

    private var floatDuration: Double {
        1.6 + Double(seed % 5) * 0.3
    }
    private var tiltDuration: Double {
        2.2 + Double((seed + 2) % 5) * 0.35
    }
    private var startDelay: Double {
        Double(seed % 4) * 0.4
    }

    var body: some View {
        Group {
            if let path = Bundle.main.path(forResource: "ClaudeCodeLogo", ofType: "png"),
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .interpolation(.high)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .drawingGroup()
                    .offset(y: floatOffset)
                    .rotationEffect(.degrees(tilt))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                withAnimation(.easeInOut(duration: floatDuration).repeatForever(autoreverses: true)) {
                    floatOffset = -2
                }
                withAnimation(.easeInOut(duration: tiltDuration).repeatForever(autoreverses: true)) {
                    tilt = 3
                }
            }
        }
    }
}

