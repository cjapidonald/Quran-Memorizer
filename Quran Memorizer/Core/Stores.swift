import SwiftUI
import Combine

final class AppPrefsStore: ObservableObject {
    @AppStorage("defaultReciter") private var rawReciter: String = Reciter.saadAlGhamdi.rawValue
    var defaultReciter: Reciter {
        get { Reciter(rawValue: rawReciter) ?? .saadAlGhamdi }
        set { rawReciter = newValue.rawValue; objectWillChange.send() }
    }
}

@MainActor
final class HighlightStore: ObservableObject {
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
    }

    func hifdhProgress(surahs: [Surah]) -> HifdhProgress {
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
}

@MainActor
final class MemorizedAyahStore: ObservableObject {
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
    }

    func memorizedAyahs(for surahId: Int) -> [Int] {
        Array(memorized[surahId] ?? []).sorted()
    }

    func memorizedCount(for surahId: Int) -> Int {
        memorized[surahId]?.count ?? 0
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
}
