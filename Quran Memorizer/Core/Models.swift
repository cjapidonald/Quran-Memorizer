import Foundation

struct Surah: Identifiable, Hashable {
    let id: Int
    let arabicName: String
    let englishName: String
    let ayahCount: Int
}

enum HighlightState: String, Codable, CaseIterable { case none, inProgress, memorized }

struct SurahHighlight: Codable, Hashable {
    let surahId: Int
    var state: HighlightState
}

enum Reciter: String, CaseIterable, Codable {
    case saadAlGhamdi = "Saad Al-Ghamdi"
    case misharyRashid = "Mishary Rashid Alafasy"

    /// Returns a URL to a sample recitation for the given surah if one exists.
    /// Currently Surah Al-Fātiḥah (1) is provided so users can try the memorizer player.
    /// The clip is bundled in the app at `Quranvn/Resources/001.mp3` so playback works offline.
    func sampleRecitation(for surah: Surah) -> URL? {
        guard surah.id == 1 else { return nil }

        if let localUrl = Self.localSampleUrl {
            return localUrl
        }

        switch self {
        case .saadAlGhamdi:
            return URL(string: "https://download.quranicaudio.com/quran/saad_al_ghamdi/001.mp3")
        case .misharyRashid:
            return URL(string: "https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/001.mp3")
        }
    }

    private static let localSampleUrl: URL? = {
        let bundle = Bundle.main
        let fileManager = FileManager.default
        let candidates: [URL?] = [
            bundle.url(
                forResource: "001",
                withExtension: "mp3",
                subdirectory: "Quranvn/Resources"
            ),
            bundle.url(forResource: "001", withExtension: "mp3"),
            bundle.resourceURL?.appendingPathComponent("Quranvn/Resources/001.mp3")
        ]

        for case let url? in candidates where fileManager.fileExists(atPath: url.path) {
            return url
        }

        return nil
    }()
}

struct HifzProgress { var completed: Int; var inProgress: Int; var total: Int }
