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
}

struct HifdhProgress { var completed: Int; var inProgress: Int; var total: Int }
