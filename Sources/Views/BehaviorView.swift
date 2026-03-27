import SwiftUI
import UniformTypeIdentifiers

struct BehaviorView: View {
    @EnvironmentObject var config: ConfigManager
    @State private var newBundleID = ""
    @State private var appSelectionError: String?

    private let commonApps: [(String, String)] = [
        ("Terminal", "com.apple.Terminal"),
        ("iTerm2", "com.googlecode.iterm2"),
        ("VS Code", "com.microsoft.VSCode"),
        ("Xcode", "com.apple.dt.Xcode")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                actionBar
                languageSection
                Divider()
                pageSizeSection
                Divider()
                inputModeSection
                Divider()
                appOverrideSection
            }
            .padding(24)
        }
        .alert(config.strings.chooseAppErrorTitle, isPresented: Binding(
            get: { appSelectionError != nil },
            set: { if !$0 { appSelectionError = nil } }
        )) {
            Button(config.strings.ok) { appSelectionError = nil }
        } message: {
            Text(appSelectionError ?? config.strings.chooseAppErrorMessage)
        }
    }

    private var actionBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.strings.behaviorTitle)
                    .font(.title3.weight(.semibold))
                Text(config.strings.behaviorDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(config.strings.resetBehaviorDefaults) {
                config.resetBehaviorDefaults()
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(config.strings.languageTitle, systemImage: "globe")
                .font(.headline)

            Text(config.strings.languageDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: Binding(
                get: { config.language },
                set: { config.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(config.strings.languageName(language)).tag(language)
                }
            }
            .pickerStyle(.menu)
        }
    }

    // MARK: - Page Size

    private var pageSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(config.strings.pageSizeTitle, systemImage: "list.number")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(1...9, id: \.self) { n in
                    pageSizeButton(n)
                }
            }

            Text(config.strings.currentPageSize(config.behavior.pageSize))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func pageSizeButton(_ n: Int) -> some View {
        let selected = config.behavior.pageSize == n
        return Button(action: { config.behavior.pageSize = n }) {
            Text("\(n)")
                .frame(width: 36, height: 36)
                .font(.system(size: 15, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? .white : .primary)
                .background(
                    Circle()
                        .fill(selected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    Circle()
                        .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.3),
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input Mode

    private var inputModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(config.strings.inputBehaviorTitle, systemImage: "keyboard")
                .font(.headline)

            VStack(spacing: 0) {
                behaviorToggleRow(
                    title: config.strings.inlinePreedit,
                    subtitle: config.strings.inlinePreeditDescription,
                    binding: $config.style.inlinePreedit,
                    icon: "text.cursor"
                )
                Divider().padding(.leading, 52)
                behaviorToggleRow(
                    title: config.strings.inlineCandidate,
                    subtitle: config.strings.inlineCandidateDescription,
                    binding: $config.style.inlineCandidate,
                    icon: "rectangle.inset.filled"
                )
                Divider().padding(.leading, 52)
                behaviorToggleRow(
                    title: config.strings.translucency,
                    subtitle: config.strings.translucencyDescription,
                    binding: $config.style.translucency,
                    icon: "circle.lefthalf.filled.righthalf.striped.horizontal"
                )
                Divider().padding(.leading, 52)
                behaviorToggleRow(
                    title: config.strings.showPaging,
                    subtitle: config.strings.showPagingDescription,
                    binding: $config.style.showPaging,
                    icon: "chevron.left.chevron.right"
                )
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private func behaviorToggleRow(
        title: String,
        subtitle: String,
        binding: Binding<Bool>,
        icon: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: binding)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - App Override

    private var appOverrideSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(config.strings.appOverrideTitle, systemImage: "app.badge.checkmark")
                .font(.headline)

            Text(config.strings.appOverrideDescription)
                .font(.callout)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(commonApps, id: \.1) { app in
                        Button(app.0) {
                            config.addAppOption(bundleID: app.1)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack {
                TextField(config.strings.bundleIDPlaceholder, text: $newBundleID)
                    .textFieldStyle(.roundedBorder)
                Button(config.strings.chooseApp) {
                    chooseLocalApp()
                }
                .buttonStyle(.bordered)
                Button(config.strings.add) {
                    config.addAppOption(bundleID: newBundleID)
                    newBundleID = ""
                }
                .disabled(newBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if config.appOptions.isEmpty {
                Text(config.strings.noAppOverrides)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            } else {
                VStack(spacing: 12) {
                    ForEach($config.appOptions) { $option in
                        AppOptionCard(option: $option, strings: config.strings) {
                            config.removeAppOption(option)
                        }
                    }
                }
                .padding(.top, 6)
            }

            Text(config.strings.appOverrideHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct AppOptionCard: View {
    @Binding var option: AppOption
    let strings: AppStrings
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.displayTitle)
                        .font(.body.weight(.medium))
                    Text("\(strings.appBundleIDLabel): \(option.bundleID)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive, action: onRemove) {
                    Label(strings.remove, systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                GridRow {
                    Toggle(strings.defaultEnglish, isOn: $option.asciiMode)
                    Toggle(strings.embeddedCandidates, isOn: $option.inlineMode)
                }
                GridRow {
                    Toggle(strings.disableInline, isOn: $option.noInline)
                    Toggle(strings.vimMode, isOn: $option.vimMode)
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}

private extension BehaviorView {
    func chooseLocalApp() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = config.strings.chooseApp

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        guard let descriptor = AppBundleDescriptor(appURL: url) else {
            appSelectionError = config.strings.chooseAppErrorMessage
            return
        }

        config.addAppOption(descriptor: descriptor)
    }
}
