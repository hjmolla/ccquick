import SwiftUI

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)

struct LaunchOptionsPanel: View {
    @Binding var options: ClaudeLaunchOptions

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("CLI Options")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                if options.hasActiveOptions {
                    Button(action: {
                        options = .default
                    }) {
                        Text("Reset All")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(claudeTerracotta)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            // Toggle options with descriptions
            VStack(spacing: 2) {
                optionRow(
                    icon: "lock.open",
                    label: "Skip Permissions",
                    desc: "All tools auto-approved without confirmation",
                    isOn: $options.skipPermissions,
                    tint: .orange
                )
                optionRow(
                    icon: "arrow.uturn.left",
                    label: "Continue",
                    desc: "Resume the most recent conversation",
                    isOn: $options.continueSession
                )
                optionRow(
                    icon: "text.alignleft",
                    label: "Verbose",
                    desc: "Show detailed logs and debug output",
                    isOn: $options.verbose
                )
            }
            .padding(.horizontal, 12)

            // Separator
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // Model picker + Max turns
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    // Model
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Model")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.8))

                        Spacer()

                        Picker("", selection: $options.model) {
                            ForEach(ClaudeModel.allCases) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 90)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(fieldBackground)

                    // Max turns
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Turns")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.primary.opacity(0.8))

                        TextField("–", value: Binding(
                            get: { options.maxTurns ?? 0 },
                            set: { options.maxTurns = $0 > 0 ? $0 : nil }
                        ), format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .frame(width: 36)
                        .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(fieldBackground)
                }

                HStack(spacing: 4) {
                    Text("Select AI model")
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("/")
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("Limit max agentic turns (0 = unlimited)")
                        .foregroundColor(.secondary.opacity(0.6))
                    Spacer()
                }
                .font(.system(size: 10, design: .rounded))
            }
            .padding(.horizontal, 16)

            // Separator
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 16)

            // System prompt
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("System Prompt")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }

                TextField("e.g. Always respond in Korean", text: $options.systemPrompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(fieldBackground)

                Text("Prepend custom instructions for this session")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)

            // Resume session ID
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("Resume Session")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                }

                TextField("Paste session ID to resume...", text: $options.resumeSessionId)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(fieldBackground)

                Text("Resume a specific past conversation by its session ID")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 16)

            // Command preview — always reserve space
            HStack(spacing: 4) {
                if options.hasActiveOptions {
                    Image(systemName: "terminal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(claudeTerracotta.opacity(0.6))

                    Text("claude \(options.buildArgs())")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(2)
                        .truncationMode(.tail)
                } else {
                    Image(systemName: "terminal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.3))

                    Text("claude")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.4))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        options.hasActiveOptions
                            ? claudeTerracotta.opacity(0.04)
                            : Color.primary.opacity(0.02)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(
                                options.hasActiveOptions
                                    ? claudeTerracotta.opacity(0.1)
                                    : Color.primary.opacity(0.05),
                                lineWidth: 0.5
                            )
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(width: 380)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.primary.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
    }

    private func optionRow(
        icon: String,
        label: String,
        desc: String,
        isOn: Binding<Bool>,
        tint: Color = claudeTerracotta
    ) -> some View {
        Button(action: {
            isOn.wrappedValue.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isOn.wrappedValue ? tint : .secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.primary.opacity(0.85))
                    Text(desc)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                }

                Spacer()

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isOn.wrappedValue ? tint : Color.primary.opacity(0.08))
                    .frame(width: 32, height: 18)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)
                            .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
                            .offset(x: isOn.wrappedValue ? 7 : -7),
                        alignment: .center
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isOn.wrappedValue ? tint.opacity(0.06) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}
