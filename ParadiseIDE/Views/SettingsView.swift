import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    var t: ParadiseTheme { vm.theme }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: t.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(t.accent)
                            Text("Customize your IDE experience")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(t.mutedColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                        SettingsSectionCard(title: "EDITOR", icon: "doc.text", theme: t) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Font Size")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                    Spacer()
                                    HStack(spacing: 12) {
                                        Button {
                                            if vm.editorFontSize > 10 { vm.editorFontSize -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(t.mutedColor)
                                        }.buttonStyle(.plain)

                                        Text("\(Int(vm.editorFontSize))pt")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(t.accent)
                                            .frame(width: 40)

                                        Button {
                                            if vm.editorFontSize < 24 { vm.editorFontSize += 1 }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(t.mutedColor)
                                        }.buttonStyle(.plain)
                                    }
                                }

                                Toggle(isOn: $vm.showLineNumbers) {
                                    Text("Line Numbers")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                }
                                .tint(t.accent)

                                Toggle(isOn: $vm.wordWrap) {
                                    Text("Word Wrap")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                }
                                .tint(t.accent)

                                Toggle(isOn: $vm.autoSave) {
                                    Text("Auto Save")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(t.textColor)
                                }
                                .tint(t.accent)
                            }
                        }

                        SettingsSectionCard(title: "APPEARANCE", icon: "paintpalette", theme: t) {
                            VStack(spacing: 16) {
                                Toggle(isOn: $vm.performanceMode) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Performance Mode")
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(t.textColor)
                                        Text("Disable particles and animations")
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundColor(t.mutedColor)
                                    }
                                }
                                .tint(t.accent)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Theme")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(t.mutedColor)

                                    ForEach(ParadiseTheme.all) { theme in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.4)) { vm.theme = theme }
                                        } label: {
                                            HStack(spacing: 12) {
                                                Circle().fill(theme.accent).frame(width: 18, height: 18)
                                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                                Text(theme.name)
                                                    .font(.system(size: 13, design: .monospaced))
                                                    .foregroundColor(vm.theme == theme ? theme.accent : t.textColor)
                                                Spacer()
                                                if vm.theme == theme {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(theme.accent)
                                                }
                                            }
                                            .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        SettingsSectionCard(title: "EDITION", icon: "crown", theme: t) {
                            VStack(spacing: 12) {
                                ForEach(IDEEdition.allCases, id: \.self) { edition in
                                    Button {
                                        vm.edition = edition
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(edition.rawValue)
                                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                    .foregroundColor(vm.edition == edition ? t.accent : t.textColor)
                                                Text(edition.price)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(t.mutedColor)
                                            }
                                            Spacer()
                                            if vm.edition == edition {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(t.accent)
                                            }
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(vm.edition == edition ? t.accent.opacity(0.08) : Color.clear)
                                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(vm.edition == edition ? t.accent.opacity(0.3) : t.surfaceBorder, lineWidth: 0.5))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        SettingsSectionCard(title: "ABOUT", icon: "info.circle", theme: t) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Paradise IDE")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(t.accent)
                                    Spacer()
                                    Text("v1.1.0")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(t.mutedColor)
                                }
                                Text("A calm, creativity-first IDE for iOS")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(t.mutedColor)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(t.accent)
                }
            }
        }
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let theme: ParadiseTheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(theme.accent)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.mutedColor)
                    .tracking(1.5)
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.surfaceBorder, lineWidth: 0.5)
                )
        )
    }
}
