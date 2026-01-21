import SwiftUI
import Combine

final class AppPrefsStore: ObservableObject {
    static let shared = AppPrefsStore()

    // Legacy support for old enum-based reciter
    @AppStorage("defaultReciter") private var rawReciter: String = Reciter.saadAlGhamdi.rawValue
    var defaultReciter: Reciter {
        get { Reciter(rawValue: rawReciter) ?? .saadAlGhamdi }
        set { rawReciter = newValue.rawValue; objectWillChange.send() }
    }

    // New dynamic qari support
    @AppStorage("selectedQariId") var selectedQariId: Int = 5 // Default: Mishary
    @AppStorage("selectedQariPath") var selectedQariPath: String = "mishaari_raashid_al_3afaasee/"
    @AppStorage("selectedQariName") var selectedQariName: String = "Mishari Rashid al-`Afasy"

    /// Get audio URL for a surah using the selected qari
    func audioURL(for surahId: Int) -> URL? {
        guard (1...114).contains(surahId) else { return nil }
        let paddedId = String(format: "%03d", surahId)
        return URL(string: "https://download.quranicaudio.com/quran/\(selectedQariPath)\(paddedId).mp3")
    }
}

@MainActor
final class HighlightStore: ObservableObject {
    static let shared = HighlightStore()

    private let key = "surahHighlights.v1"
    @Published private(set) var highlights: [Int: HighlightState] = [:]
    init() { load() }

    func state(for surahId: Int) -> HighlightState { highlights[surahId] ?? .none }

    func setState(_ state: HighlightState, for surahId: Int) {
        var copy = highlights
        if state == .none {
            copy.removeValue(forKey: surahId)
        } else {
            copy[surahId] = state
        }
        highlights = copy
        save()
        syncToCloudIfNeeded()
    }

    func hifzProgress(surahs: [Surah]) -> HifzProgress {
        var completed = 0, inProgress = 0
        for s in surahs {
            switch highlights[s.id] ?? .none {
            case .memorized: completed += 1
            case .inProgress: inProgress += 1
            case .none: break
            }
        }
        return .init(completed: completed, inProgress: inProgress, total: surahs.count)
    }

    /// Replace all highlights (used by CloudKit sync)
    func replaceAll(_ newHighlights: [Int: HighlightState]) {
        highlights = newHighlights
        save()
    }

    private func save() {
        let compact = highlights.reduce(into: [String: String]()) { partialResult, element in
            partialResult[String(element.key)] = element.value.rawValue
        }
        UserDefaults.standard.set(compact, forKey: key)
    }

    private func load() {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: String] else { return }
        var out: [Int: HighlightState] = [:]
        for (k,v) in dict {
            if let id = Int(k), let state = HighlightState(rawValue: v) { out[id] = state }
        }
        highlights = out
    }

    private func syncToCloudIfNeeded() {
        guard AuthManager.shared.isSignedIn else { return }
        Task {
            await CloudSyncManager.shared.syncToCloud()
        }
    }
}

@MainActor
final class MemorizedAyahStore: ObservableObject {
    static let shared = MemorizedAyahStore()

    private let key = "memorizedAyahs.v1"
    @Published private(set) var memorized: [Int: Set<Int>] = [:]

    init() { load() }

    func isMemorized(surahId: Int, ayah: Int) -> Bool {
        memorized[surahId]?.contains(ayah) ?? false
    }

    @discardableResult
    func toggleMemorized(surahId: Int, ayah: Int) -> Bool {
        let newValue = !(memorized[surahId]?.contains(ayah) ?? false)
        setMemorized(newValue, surahId: surahId, ayah: ayah)
        return newValue
    }

    func setMemorized(_ isMemorized: Bool, surahId: Int, ayah: Int) {
        var updated = memorized
        var set = updated[surahId] ?? []
        if isMemorized {
            set.insert(ayah)
            updated[surahId] = set
        } else {
            set.remove(ayah)
            if set.isEmpty {
                updated.removeValue(forKey: surahId)
            } else {
                updated[surahId] = set
            }
        }
        memorized = updated
        save()
        syncToCloudIfNeeded()
    }

    func memorizedAyahs(for surahId: Int) -> [Int] {
        Array(memorized[surahId] ?? []).sorted()
    }

    func memorizedCount(for surahId: Int) -> Int {
        memorized[surahId]?.count ?? 0
    }

    /// Replace all memorized ayahs (used by CloudKit sync)
    func replaceAll(_ newMemorized: [Int: Set<Int>]) {
        memorized = newMemorized
        save()
    }

    private func save() {
        let compact = memorized.reduce(into: [String: [Int]]()) { partialResult, element in
            partialResult[String(element.key)] = Array(element.value).sorted()
        }
        UserDefaults.standard.set(compact, forKey: key)
    }

    private func load() {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: [Int]] else { return }
        var out: [Int: Set<Int>] = [:]
        for (k, v) in dict {
            if let id = Int(k) {
                out[id] = Set(v)
            }
        }
        memorized = out
    }

    private func syncToCloudIfNeeded() {
        guard AuthManager.shared.isSignedIn else { return }
        Task {
            await CloudSyncManager.shared.syncToCloud()
        }
    }
}
