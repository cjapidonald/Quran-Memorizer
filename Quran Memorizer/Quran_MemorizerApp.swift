import SwiftUI

@main
struct Quran_MemorizerApp: App {
    @StateObject private var nav = AppNav()
    @StateObject private var theme = ThemeManager()
    @StateObject private var prefs = AppPrefsStore()
    @StateObject private var highlights = HighlightStore()
    @StateObject private var memorizedAyahs = MemorizedAyahStore()
    @StateObject private var memorizer = MemorizerState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(nav)
                .environmentObject(theme)
                .environmentObject(prefs)
                .environmentObject(highlights)
                .environmentObject(memorizedAyahs)
                .environmentObject(memorizer)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
