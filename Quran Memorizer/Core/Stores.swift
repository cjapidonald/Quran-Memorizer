import SwiftUI
import Combine

final class AppPrefsStore: ObservableObject {
    @AppStorage("defaultReciter") private var rawReciter: String = Reciter.saadAlGhamdi.rawValue
    var defaultReciter: Reciter {
        get { Reciter(rawValue: rawReciter) ?? .saadAlGhamdi }
        set { rawReciter = newValue.rawValue; objectWillChange.send() }
    }
}

final class HighlightStore: ObservableObject {
    private let key = "surahHighlights.v1"
    @Published private(set) var highlights: [Int: HighlightState] = [:]
    init() { load() }

    func state(for surahId: Int) -> HighlightState { highlights[surahId] ?? .none }

    func setState(_ state: HighlightState, for surahId: Int) {
        highlights[surahId] = state
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
        let compact = highlights.mapValues { $0.rawValue }
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
