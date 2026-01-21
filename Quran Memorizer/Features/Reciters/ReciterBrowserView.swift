import SwiftUI

struct ReciterBrowserView: View {
    @EnvironmentObject private var qariService: QariService
    @EnvironmentObject private var downloadManager: AudioDownloadManager
    @EnvironmentObject private var prefs: AppPrefsStore

    @State private var searchText = ""
    @State private var selectedQari: Qari?
    @State private var showDownloadSheet = false

    private var filteredQaris: [Qari] {
        if searchText.isEmpty {
            return qariService.qaris
        }
        return qariService.qaris.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.arabicName.contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if qariService.isLoading && qariService.qaris.isEmpty {
                    ProgressView("Loading reciters...")
                } else if let error = qariService.error, qariService.qaris.isEmpty {
                    errorView(error)
                } else {
                    qariList
                }
            }
            .navigationTitle("Reciters")
            .searchable(text: $searchText, prompt: "Search reciters")
            .refreshable {
                await qariService.fetchQaris(forceRefresh: true)
            }
            .task {
                await qariService.fetchQaris()
            }
            .sheet(item: $selectedQari) { qari in
                ReciterDetailSheet(qari: qari)
            }
        }
    }

    private var qariList: some View {
        List {
            Section {
                Text("\(qariService.qaris.count) reciters available")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(filteredQaris) { qari in
                ReciterRow(qari: qari, isSelected: prefs.selectedQariId == qari.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedQari = qari
                    }
            }
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task {
                    await qariService.fetchQaris(forceRefresh: true)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct ReciterRow: View {
    let qari: Qari
    let isSelected: Bool
    @EnvironmentObject private var downloadManager: AudioDownloadManager

    private var downloadCount: Int {
        downloadManager.downloadCount(for: qari.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(qari.name)
                        .font(.body.weight(.medium))
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                Text(qari.arabicName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if downloadCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(downloadCount)")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.15)))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct ReciterDetailSheet: View {
    let qari: Qari
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var prefs: AppPrefsStore
    @EnvironmentObject private var downloadManager: AudioDownloadManager
    @State private var downloadingSurahs: Set<Int> = []

    private let surahs = StaticSurahs.all

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(qari.arabicName)
                            .font(.title2)
                        Text(qari.name)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button {
                        prefs.selectedQariId = qari.id
                        prefs.selectedQariPath = qari.relativePath
                        prefs.selectedQariName = qari.name
                        dismiss()
                    } label: {
                        HStack {
                            Label("Set as Default Reciter", systemImage: "star")
                            Spacer()
                            if prefs.selectedQariId == qari.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Label("Downloaded", systemImage: "arrow.down.circle.fill")
                        Spacer()
                        Text("\(downloadManager.downloadCount(for: qari.id)) / 114 surahs")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            await downloadManager.downloadAll(qari: qari, surahs: surahs)
                        }
                    } label: {
                        Label("Download All Surahs", systemImage: "arrow.down.to.line")
                    }
                    .disabled(downloadManager.downloadCount(for: qari.id) == 114)

                    if downloadManager.downloadCount(for: qari.id) > 0 {
                        Button(role: .destructive) {
                            downloadManager.deleteAll(qariId: qari.id)
                        } label: {
                            Label("Delete All Downloads", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Offline Downloads")
                }

                Section {
                    ForEach(surahs) { surah in
                        SurahDownloadRow(
                            surah: surah,
                            qari: qari,
                            isDownloaded: downloadManager.isDownloaded(qariId: qari.id, surahId: surah.id),
                            isDownloading: downloadManager.activeDownloads["\(qari.id)_\(surah.id)"] != nil
                        )
                    }
                } header: {
                    Text("Surahs")
                }
            }
            .navigationTitle("Reciter Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SurahDownloadRow: View {
    let surah: Surah
    let qari: Qari
    let isDownloaded: Bool
    let isDownloading: Bool
    @EnvironmentObject private var downloadManager: AudioDownloadManager

    var body: some View {
        HStack {
            Text("\(surah.id)")
                .font(.caption.weight(.semibold))
                .frame(width: 30)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(surah.englishName)
                    .font(.body)
                Text(surah.arabicName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDownloading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if isDownloaded {
                Menu {
                    Button(role: .destructive) {
                        downloadManager.delete(qariId: qari.id, surahId: surah.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Button {
                    Task {
                        await downloadManager.download(qari: qari, surah: surah)
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ReciterBrowserView()
        .environmentObject(QariService.shared)
        .environmentObject(AudioDownloadManager.shared)
        .environmentObject(AppPrefsStore())
}
