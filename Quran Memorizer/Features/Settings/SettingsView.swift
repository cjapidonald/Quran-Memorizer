import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var prefs: AppPrefsStore
    @EnvironmentObject private var downloadManager: AudioDownloadManager
    @State private var showShare = false
    @State private var showDeleteAllConfirm = false
    private let optionColumns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: Binding(
                        get: { theme.themeStyle == .light },
                        set: { theme.themeStyle = $0 ? .light : .dark }
                    )) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Light mode")
                                .font(.footnote.weight(.semibold))
                            Text("Switch between the dark (default) and white interface.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))

                    HStack {
                        Text("Glass intensity")
                        Slider(value: $theme.glassIntensity, in: 0...0.6)
                    }
                }

                Section {
                    HStack {
                        Label("Current Reciter", systemImage: "person.wave.2")
                        Spacer()
                        Text(prefs.selectedQariName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    NavigationLink {
                        ReciterBrowserView()
                    } label: {
                        Label("Browse All Reciters", systemImage: "music.note.list")
                    }
                } header: {
                    Text("Audio")
                } footer: {
                    Text("Choose from 100+ reciters and download surahs for offline listening.")
                }

                Section {
                    HStack {
                        Label("Storage Used", systemImage: "internaldrive")
                        Spacer()
                        Text(downloadManager.formattedStorageUsed)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Downloaded Surahs", systemImage: "arrow.down.circle.fill")
                        Spacer()
                        Text("\(downloadManager.downloads.count)")
                            .foregroundStyle(.secondary)
                    }

                    if !downloadManager.downloads.isEmpty {
                        Button(role: .destructive) {
                            showDeleteAllConfirm = true
                        } label: {
                            Label("Delete All Downloads", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Offline Storage")
                } footer: {
                    Text("Downloaded surahs are stored on your device for offline listening.")
                }

                Section {
                    NavigationLink {
                        AccountView()
                    } label: {
                        Label("Account & iCloud Sync", systemImage: "person.crop.circle")
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Sign in with Apple to sync your progress across devices.")
                }

                Section("About") {
                    Text("Quran Memorizer\nDeveloper: Donald Cjapi (2025)")
                    Button("Share this app") { showShare = true }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showShare) {
                ShareSheet(activityItems: ["Check out Quran Memorizer — a simple app for hifz with A↔B loop playback."])
            }
            .alert("Delete All Downloads?", isPresented: $showDeleteAllConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    downloadManager.deleteAllDownloads()
                }
            } message: {
                Text("This will remove all \(downloadManager.downloads.count) downloaded surahs and free up \(downloadManager.formattedStorageUsed) of storage.")
            }
        }
    }

    @ViewBuilder
    private func selectionButton(title: String, isSelected: Bool, swatch: Color? = nil) -> some View {
        HStack(spacing: 10) {
            if let swatch {
                Circle()
                    .fill(swatch)
                    .frame(width: 18, height: 18)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
