import SwiftUI

struct SurahsView: View {
    @EnvironmentObject private var nav: AppNav
    @EnvironmentObject private var highlights: HighlightStore
    @State private var query: String = ""

    private var filtered: [Surah] {
        let all = StaticSurahs.all
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.englishName.localizedCaseInsensitiveContains(query) ||
            $0.arabicName.contains(query) ||
            "\($0.id)".contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section { HeaderCard() }
                Section {
                    ForEach(filtered) { surah in
                        SurahRow(surah: surah)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                nav.selectedSurah = surah
                                nav.selectedTab = 1
                            }
                    }
                }
            }
            .navigationTitle("Surahs")
            .searchable(text: $query, prompt: "Search surah")
        }
    }

    @ViewBuilder
    private func HeaderCard() -> some View {
        let prog = highlights.hifdhProgress(surahs: StaticSurahs.all)
        let pct = prog.total == 0 ? 0 : Double(prog.completed) / Double(prog.total)
        ZStack {
            GlassBackground(intensity: 0.18, cornerRadius: 14)
            VStack(alignment: .leading, spacing: 10) {
                Text("Hifdh Progress").font(.headline)
                GradientProgressBar(progress: pct, height: 12)
                HStack {
                    Label("Memorized \(prog.completed)", systemImage: "checkmark.seal.fill")
                    Spacer()
                    Label("In progress \(prog.inProgress)", systemImage: "hourglass")
                    Spacer()
                    Text("Total \(prog.total)").foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            .padding()
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 6)
    }
}

private struct SurahRow: View {
    @EnvironmentObject private var highlights: HighlightStore
    let surah: Surah
    @State private var showPicker = false

    var state: HighlightState { highlights.state(for: surah.id) }
    var stateColor: Color {
        switch state {
        case .none: return .gray.opacity(0.25)
        case .inProgress: return .yellow.opacity(0.7)
        case .memorized: return .green.opacity(0.8)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(surah.id)")
                .font(.subheadline.weight(.semibold))
                .frame(width: 30)
                .padding(6)
                .background(Circle().fill(stateColor))
            VStack(alignment: .leading) {
                Text(surah.englishName).font(.body.weight(.semibold))
                Text(surah.arabicName).font(.title3).minimumScaleFactor(0.6)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Capsule()
                .fill(state == .none ? Color.secondary.opacity(0.18) : stateColor)
                .frame(width: 60, height: 10)
                .overlay(
                    Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        }
        .contextMenu {
            Button("None") { set(.none) }
            Button("In progress") { set(.inProgress) }
            Button("Memorized") { set(.memorized) }
        }
        .onLongPressGesture { showPicker = true }
        .confirmationDialog("Highlight", isPresented: $showPicker) {
            Button("None") { set(.none) }
            Button("In progress", role: .none) { set(.inProgress) }
            Button("Memorized") { set(.memorized) }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func set(_ new: HighlightState) {
        withAnimation { highlights.setState(new, for: surah.id) }
    }
}

#Preview("Surahs") {
    RootTabView()
        .environmentObject(AppNav())
        .environmentObject(ThemeManager())
        .environmentObject(AppPrefsStore())
        .environmentObject(HighlightStore())
        .environmentObject(MemorizedAyahStore())
        .environmentObject(MemorizerState())
}
