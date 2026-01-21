import Foundation
import Combine

/// Tracks a downloaded surah
struct DownloadedSurah: Codable, Identifiable, Hashable {
    var id: String { "\(qariId)_\(surahId)" }
    let qariId: Int
    let qariName: String
    let surahId: Int
    let surahName: String
    let fileSize: Int64
    let downloadDate: Date
}

/// Download progress for a surah
struct DownloadProgress: Identifiable {
    var id: String { "\(qariId)_\(surahId)" }
    let qariId: Int
    let surahId: Int
    var progress: Double
    var isCompleted: Bool
    var error: String?
}

/// Manages offline audio downloads
@MainActor
final class AudioDownloadManager: ObservableObject {
    static let shared = AudioDownloadManager()

    @Published private(set) var downloads: [DownloadedSurah] = []
    @Published private(set) var activeDownloads: [String: DownloadProgress] = [:]
    @Published private(set) var totalStorageUsed: Int64 = 0

    private let downloadsKey = "downloadedSurahs.v1"
    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]

    private var downloadsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("QuranAudio", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        loadDownloads()
        calculateStorageUsed()
    }

    // MARK: - Public Methods

    /// Check if a surah is downloaded for a specific qari
    func isDownloaded(qariId: Int, surahId: Int) -> Bool {
        downloads.contains { $0.qariId == qariId && $0.surahId == surahId }
    }

    /// Get local file URL for a downloaded surah
    func localURL(qariId: Int, surahId: Int) -> URL? {
        guard isDownloaded(qariId: qariId, surahId: surahId) else { return nil }
        let filename = "\(qariId)_\(String(format: "%03d", surahId)).mp3"
        let url = downloadsDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Download a surah for offline use
    func download(qari: Qari, surah: Surah) async {
        let key = "\(qari.id)_\(surah.id)"

        // Skip if already downloaded or downloading
        guard !isDownloaded(qariId: qari.id, surahId: surah.id),
              activeDownloads[key] == nil,
              let remoteURL = qari.audioURL(for: surah.id) else {
            return
        }

        // Start progress tracking
        activeDownloads[key] = DownloadProgress(
            qariId: qari.id,
            surahId: surah.id,
            progress: 0,
            isCompleted: false
        )

        do {
            let localURL = downloadsDirectory.appendingPathComponent("\(qari.id)_\(String(format: "%03d", surah.id)).mp3")

            // Download with progress
            let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)

            // Get file size
            let fileSize = (response as? HTTPURLResponse)
                .flatMap { Int64($0.value(forHTTPHeaderField: "Content-Length") ?? "0") }
                ?? (try? fileManager.attributesOfItem(atPath: tempURL.path)[.size] as? Int64)
                ?? 0

            // Move to permanent location
            if fileManager.fileExists(atPath: localURL.path) {
                try fileManager.removeItem(at: localURL)
            }
            try fileManager.moveItem(at: tempURL, to: localURL)

            // Record download
            let download = DownloadedSurah(
                qariId: qari.id,
                qariName: qari.name,
                surahId: surah.id,
                surahName: surah.englishName,
                fileSize: fileSize,
                downloadDate: Date()
            )
            downloads.append(download)
            saveDownloads()
            calculateStorageUsed()

            // Mark complete
            activeDownloads[key]?.progress = 1.0
            activeDownloads[key]?.isCompleted = true

            // Remove from active after delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            activeDownloads.removeValue(forKey: key)

        } catch {
            activeDownloads[key]?.error = error.localizedDescription
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            activeDownloads.removeValue(forKey: key)
        }
    }

    /// Download all surahs for a qari
    func downloadAll(qari: Qari, surahs: [Surah]) async {
        for surah in surahs {
            await download(qari: qari, surah: surah)
        }
    }

    /// Delete a downloaded surah
    func delete(qariId: Int, surahId: Int) {
        let filename = "\(qariId)_\(String(format: "%03d", surahId)).mp3"
        let url = downloadsDirectory.appendingPathComponent(filename)

        try? fileManager.removeItem(at: url)
        downloads.removeAll { $0.qariId == qariId && $0.surahId == surahId }
        saveDownloads()
        calculateStorageUsed()
    }

    /// Delete all downloads for a qari
    func deleteAll(qariId: Int) {
        let toDelete = downloads.filter { $0.qariId == qariId }
        for item in toDelete {
            delete(qariId: item.qariId, surahId: item.surahId)
        }
    }

    /// Delete all downloads
    func deleteAllDownloads() {
        for download in downloads {
            delete(qariId: download.qariId, surahId: download.surahId)
        }
    }

    /// Get downloads grouped by qari
    func downloadsByQari() -> [Int: [DownloadedSurah]] {
        Dictionary(grouping: downloads, by: { $0.qariId })
    }

    /// Get download count for a qari
    func downloadCount(for qariId: Int) -> Int {
        downloads.filter { $0.qariId == qariId }.count
    }

    /// Format storage size for display
    var formattedStorageUsed: String {
        ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }

    // MARK: - Private Methods

    private func loadDownloads() {
        guard let data = UserDefaults.standard.data(forKey: downloadsKey),
              let decoded = try? JSONDecoder().decode([DownloadedSurah].self, from: data) else {
            return
        }
        // Verify files still exist
        downloads = decoded.filter { download in
            let filename = "\(download.qariId)_\(String(format: "%03d", download.surahId)).mp3"
            let url = downloadsDirectory.appendingPathComponent(filename)
            return fileManager.fileExists(atPath: url.path)
        }
        if downloads.count != decoded.count {
            saveDownloads()
        }
    }

    private func saveDownloads() {
        guard let data = try? JSONEncoder().encode(downloads) else { return }
        UserDefaults.standard.set(data, forKey: downloadsKey)
    }

    private func calculateStorageUsed() {
        var total: Int64 = 0
        for download in downloads {
            let filename = "\(download.qariId)_\(String(format: "%03d", download.surahId)).mp3"
            let url = downloadsDirectory.appendingPathComponent(filename)
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        totalStorageUsed = total
    }
}
