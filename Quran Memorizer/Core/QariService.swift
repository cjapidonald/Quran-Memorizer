import Foundation
import Combine

/// Represents a Qari (reciter) from the QuranicAudio API
struct Qari: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let arabicName: String
    let relativePath: String
    let fileFormats: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case arabicName = "arabic_name"
        case relativePath = "relative_path"
        case fileFormats = "file_formats"
    }

    /// Base URL for streaming/downloading audio
    var baseURL: URL? {
        URL(string: "https://download.quranicaudio.com/quran/\(relativePath)")
    }

    /// URL for a specific surah (1-114)
    func audioURL(for surahId: Int) -> URL? {
        guard (1...114).contains(surahId) else { return nil }
        let paddedId = String(format: "%03d", surahId)
        return baseURL?.appendingPathComponent("\(paddedId).mp3")
    }
}

/// Service for fetching Qaris from QuranicAudio API
@MainActor
final class QariService: ObservableObject {
    static let shared = QariService()

    @Published private(set) var qaris: [Qari] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let cacheKey = "cachedQaris.v1"
    private let apiURL = URL(string: "https://quranicaudio.com/api/qaris")!

    init() {
        loadCached()
    }

    /// Fetch qaris from API (or use cache if recent)
    func fetchQaris(forceRefresh: Bool = false) async {
        guard !isLoading else { return }

        // Use cache if we have data and not forcing refresh
        if !forceRefresh && !qaris.isEmpty {
            return
        }

        isLoading = true
        error = nil

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decoded = try JSONDecoder().decode([Qari].self, from: data)
            qaris = decoded.sorted { $0.name < $1.name }
            saveToCache(data)
        } catch {
            self.error = "Failed to load reciters: \(error.localizedDescription)"
            // Keep using cached data if available
        }

        isLoading = false
    }

    private func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([Qari].self, from: data) else {
            // Provide default reciters if no cache
            qaris = defaultQaris
            return
        }
        qaris = decoded.sorted { $0.name < $1.name }
    }

    private func saveToCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    /// Default reciters in case API is unavailable
    private var defaultQaris: [Qari] {
        [
            Qari(id: 5, name: "Mishari Rashid al-`Afasy", arabicName: "مشاري راشد العفاسي",
                 relativePath: "mishaari_raashid_al_3afaasee/", fileFormats: "mp3"),
            Qari(id: 6, name: "Sa`d al-Ghamdi", arabicName: "سعد الغامدي",
                 relativePath: "sa3d_al-ghaamidi/complete/", fileFormats: "mp3"),
            Qari(id: 4, name: "Sa`ud ash-Shuraym", arabicName: "سعود الشريم",
                 relativePath: "sa3ood_al-shuraym/", fileFormats: "mp3"),
            Qari(id: 1, name: "Abdullah Awad al-Juhani", arabicName: "عبدالله عواد الجهني",
                 relativePath: "abdullaah_3awwaad_al-juhaynee/", fileFormats: "mp3")
        ]
    }
}
