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
    /// All surahs are streamed from QuranicAudio.com for both supported reciters.
    /// Surah Al-Fātiḥah (1) is additionally bundled at `Quranvn/Resources/001.mp3`
    /// so playback works offline.
    func sampleRecitation(for surah: Surah) -> URL? {
        guard (1...114).contains(surah.id) else { return nil }

        let paddedId = String(format: "%03d", surah.id)

        if surah.id == 1, let localUrl = Self.localSampleUrl {
            return localUrl
        }

        return URL(string: baseUrlString + "\(paddedId).mp3")
    }

    private var baseUrlString: String {
        switch self {
        case .saadAlGhamdi:
            return "https://download.quranicaudio.com/quran/saad_al_ghamdi/"
        case .misharyRashid:
            return "https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/"
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
