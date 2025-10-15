import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var nav: AppNav
    var body: some View {
        TabView(selection: $nav.selectedTab) {
            SurahsView()
                .tabItem { SurahsTabIcon() }
                .tag(0)

            MemorizerView()
                .tabItem {
                    Image(systemName: "headphones")
                    Text("Memorizer")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(2)
        }
    }
}

private struct SurahsTabIcon: View {
    @EnvironmentObject private var highlights: HighlightStore
    private var progress: Double {
        let prog = highlights.hifdhProgress(surahs: StaticSurahs.all)
        return prog.total == 0 ? 0 : Double(prog.completed) / Double(prog.total)
    }
    var body: some View {
        ZStack {
            Image(systemName: "list.bullet")
            Circle()
                .trim(from: 0, to: progress)
                .stroke(lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .frame(width: 16, height: 16)
                .offset(x: 12, y: -10)
        }
        Text("Surahs")
    }
}
