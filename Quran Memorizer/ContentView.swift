import SwiftUI
struct ContentView: View { var body: some View { RootTabView() } }
#Preview {
    RootTabView()
        .environmentObject(AppNav())
        .environmentObject(ThemeManager())
        .environmentObject(AppPrefsStore())
        .environmentObject(HighlightStore())
        .environmentObject(MemorizedAyahStore())
        .environmentObject(MemorizerState())
}
