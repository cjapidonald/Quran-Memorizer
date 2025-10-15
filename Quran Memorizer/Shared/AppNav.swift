import SwiftUI
import Combine

final class AppNav: ObservableObject {
    @Published var selectedTab: Int = 0       // 0: Surahs, 1: Memorizer, 2: Settings
    @Published var selectedSurah: Surah? = nil
}
