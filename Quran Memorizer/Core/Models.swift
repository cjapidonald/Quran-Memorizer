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
    /// Surah Al-Fātiḥah (1) is additionally bundled at `Quran/Resources/Saad01/001.mp3`
    /// so playback works offline. Selected early surahs are packaged as
    /// On-Demand Resources so they can be downloaded for offline playback.
    func sampleRecitation(for surah: Surah) -> URL? {
        guard (1...114).contains(surah.id) else { return nil }

        if let local = localSampleURL(for: surah.id) {
            return local
        }

        return streamingSampleURL(for: surah)
    }

    private var baseUrlString: String {
        switch self {
        case .saadAlGhamdi:
            return "https://download.quranicaudio.com/quran/saad_al_ghamdi/"
        case .misharyRashid:
            return "https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/"
        }
    }

    func streamingSampleURL(for surah: Surah) -> URL? {
        guard (1...114).contains(surah.id) else { return nil }
        let paddedId = String(format: "%03d", surah.id)
        return URL(string: baseUrlString + "\(paddedId).mp3")
    }

    func onDemandResourceTag(for surahId: Int) -> String? {
        guard (1...4).contains(surahId) else { return nil }
        let padded = String(format: "%03d", surahId)
        switch self {
        case .saadAlGhamdi:
            return "s\(padded)"
        case .misharyRashid:
            return "m\(padded)"
        }
    }

    private func localSampleURL(for surahId: Int, in bundle: Bundle = .main) -> URL? {
        if let subdirectory = onDemandSubdirectory(for: surahId) {
            let fileManager = FileManager.default
            let candidates = onDemandResourceFilenames(for: surahId).flatMap { name -> [URL?] in
                [
                    bundle.url(
                        forResource: name,
                        withExtension: "mp3",
                        subdirectory: subdirectory
                    ),
                    bundle.resourceURL?.appendingPathComponent("\(subdirectory)/\(name).mp3")
                ]
            }

            for case let url? in candidates where fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        if surahId == 1, let url = Self.bundledFatihahSampleUrl {
            return url
        }

        return nil
    }

    private func onDemandSubdirectory(for surahId: Int) -> String? {
        guard (1...4).contains(surahId) else { return nil }
        switch self {
        case .saadAlGhamdi:
            return "Quran/Resources/Saad01"
        case .misharyRashid:
            return "Quran/Resources/Mishary01"
        }
    }

    private func onDemandResourceFilenames(for surahId: Int) -> [String] {
        let padded = String(format: "%03d", surahId)
        switch self {
        case .saadAlGhamdi:
            return ["s\(padded)", padded]
        case .misharyRashid:
            return ["m\(padded)", padded]
        }
    }

    private static let bundledFatihahSampleUrl: URL? = {
        let bundle = Bundle.main
        let fileManager = FileManager.default
        let subdirectories = [
            "Quran/Resources",
            "Quran/Resources/Saad01",
            "Quran/Resources/Mishary01"
        ]

        let resourceNames = ["001", "s001", "m001"]

        let candidates: [URL?] = subdirectories.flatMap { subdirectory in
            resourceNames.map { name in
                bundle.url(
                    forResource: name,
                    withExtension: "mp3",
                    subdirectory: subdirectory
                )
            }
        } + [
            bundle.url(forResource: "001", withExtension: "mp3"),
            bundle.resourceURL?.appendingPathComponent("Quran/Resources/001.mp3"),
            bundle.resourceURL?.appendingPathComponent("Quran/Resources/Saad01/001.mp3"),
            bundle.resourceURL?.appendingPathComponent("Quran/Resources/Mishary01/m001.mp3")
        ]

        for case let url? in candidates where fileManager.fileExists(atPath: url.path) {
            return url
        }

        return nil
    }()
}

struct HifzProgress { var completed: Int; var inProgress: Int; var total: Int }
