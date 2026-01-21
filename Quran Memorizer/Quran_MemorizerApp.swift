import SwiftUI

@main
struct Quran_MemorizerApp: App {
    @StateObject private var nav = AppNav()
    @StateObject private var theme = ThemeManager()
    @StateObject private var memorizer = MemorizerState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(nav)
                .environmentObject(theme)
                .environmentObject(AppPrefsStore.shared)
                .environmentObject(HighlightStore.shared)
                .environmentObject(MemorizedAyahStore.shared)
                .environmentObject(memorizer)
                .environmentObject(QariService.shared)
                .environmentObject(AudioDownloadManager.shared)
                .environmentObject(AuthManager.shared)
                .environmentObject(CloudSyncManager.shared)
                .preferredColorScheme(theme.colorScheme)
                .task {
                    await QariService.shared.fetchQaris()
                    AuthManager.shared.checkAuthStatus()
                }
        }
    }
}
