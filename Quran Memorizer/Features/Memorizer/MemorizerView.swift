import SwiftUI

struct MemorizerView: View {
    @EnvironmentObject private var nav: AppNav
    @EnvironmentObject private var prefs: AppPrefsStore
    @EnvironmentObject private var mem: MemorizerState
    @EnvironmentObject private var highlights: HighlightStore
    @EnvironmentObject private var memorizedAyahs: MemorizedAyahStore
    @State private var showPlayerControls = false
    @State private var textLanguage: SurahTextLanguage = .both

    var body: some View {
        NavigationStack {
            content
            .navigationTitle("Memorizer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    reciterPicker
                }
            }
            .onChange(of: nav.selectedSurah) { _, newValue in
                mem.selectedSurah = newValue
            }
            .onAppear {
                if nav.selectedSurah == nil {
                    nav.selectedSurah = StaticSurahs.all.first { $0.id == 1 }
                }
                if mem.selectedReciter != prefs.defaultReciter {
                    mem.selectedReciter = prefs.defaultReciter
                }
                if mem.selectedSurah?.id != nav.selectedSurah?.id {
                    mem.selectedSurah = nav.selectedSurah
                    showPlayerControls = false
                    textLanguage = .both
                }
            }
            .onChange(of: prefs.defaultReciter) { _, newValue in
                mem.selectedReciter = newValue
            }
            .onChange(of: nav.selectedSurah) { _, _ in
                withAnimation(.spring(duration: 0.25)) {
                    showPlayerControls = false
                    textLanguage = .both
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let s = nav.selectedSurah {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(for: s)
                    playerSection(for: s)
                    if let text = SurahTexts.text(for: s.id) {
                        surahTextSection(text, for: s)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            emptyState
        }
    }

    private var reciterPicker: some View {
        Menu {
            Picker("Reciter", selection: $mem.selectedReciter) {
                ForEach(Reciter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
        } label: {
            Label(mem.selectedReciter.rawValue, systemImage: "person.wave.2")
        }
    }

    private func header(for s: Surah) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(s.englishName)")
                .font(.title2.bold())
            Text(s.arabicName)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sampleStatus(for status: MemorizerState.SampleAvailability) -> some View {
        switch status {
        case .loading:
            HStack(spacing: 6) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7, anchor: .center)
                Text("Loading Surah Al-Fātiḥah sample…")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        case .ready:
            Label("Sample recitation ready – \(mem.selectedReciter.rawValue)", systemImage: "waveform")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .failed:
            Label("Couldn't load the sample audio. Check your connection.", systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(.red)
        case .none:
            Label("Tap play to simulate playback.", systemImage: "play.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func playerSection(for surah: Surah) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    showPlayerControls.toggle()
                }
                if !showPlayerControls {
                    mem.pause()
                }
            } label: {
                HStack {
                    Image(systemName: showPlayerControls ? "waveform.circle.fill" : "play.circle")
                        .font(.system(size: 28))
                    Text(showPlayerControls ? "Hide player" : "Show player")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showPlayerControls ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showPlayerControls)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.secondary.opacity(0.12))
                )
            }
            .buttonStyle(.plain)

            if showPlayerControls {
                if surah.id == 1 {
                    sampleStatus(for: mem.sampleAvailability)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Label("Audio samples are currently provided for Surah Al-Fātiḥah.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                timeline
                    .transition(.opacity.combined(with: .move(edge: .top)))
                controls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var timeline: some View {
        VStack(spacing: 12) {
            Text(mem.currentTime.mmss + " / " + mem.duration.mmss)
                .font(.system(.title3, design: .rounded).monospacedDigit())

            ABRangeSlider(start: $mem.loopStart, end: $mem.loopEnd, duration: mem.duration) { editing in
                if !editing && mem.isLooping {
                    mem.seek(to: mem.loopStart)
                }
            }

            // playback position
            GeometryReader { geo in
                let width = max(1, geo.size.width)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.18))
                    Capsule().fill(Color.accentColor.opacity(0.5))
                        .frame(width: CGFloat(mem.currentTime/mem.duration) * width)
                }
                .frame(height: 6)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    let ratio = max(0, min(1, v.location.x / width))
                    mem.seek(to: ratio * mem.duration)
                })
            }
            .frame(height: 6)
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                mem.setLoop(start: mem.currentTime, end: mem.loopEnd)
            } label: { Label("Set A", systemImage: "a.circle") }

            Button {
                mem.setLoop(start: mem.loopStart, end: mem.currentTime)
            } label: { Label("Set B", systemImage: "b.circle") }

            Button {
                withAnimation { mem.isLooping.toggle() }
                if mem.isLooping { mem.seek(to: mem.loopStart) }
            } label: {
                Label("Loop", systemImage: mem.isLooping ? "repeat.circle.fill" : "repeat.circle")
            }

            Spacer()

            Button {
                mem.togglePlay()
            } label: {
                Image(systemName: mem.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }

    private func surahTextSection(_ text: SurahTextContent, for surah: Surah) -> some View {
        let totalAyahs = surah.ayahCount > 0 ? surah.ayahCount : text.arabic.count
        let indices = ayahIndices(for: text, surah: surah)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Surah text")
                .font(.headline)

            Picker("Language", selection: $textLanguage) {
                ForEach(SurahTextLanguage.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Text("Double-click an ayah to toggle its memorized status.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if textLanguage == .memorized && indices.isEmpty {
                Label("No ayahs memorized yet.", systemImage: "bookmark.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.secondary.opacity(0.08))
                    )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(indices, id: \.self) { index in
                        ayahCard(for: index, text: text, surah: surah, totalAyahs: totalAyahs)
                    }
                }
            }
        }
    }

    private func ayahIndices(for text: SurahTextContent, surah: Surah) -> [Int] {
        let total = text.arabic.count
        switch textLanguage {
        case .memorized:
            return memorizedAyahs
                .memorizedAyahs(for: surah.id)
                .map { $0 - 1 }
                .filter { $0 >= 0 && $0 < total }
        default:
            return Array(0..<total)
        }
    }

    private func ayahCard(for index: Int, text: SurahTextContent, surah: Surah, totalAyahs: Int) -> some View {
        let ayahNumber = index + 1
        let verse = index < text.arabic.count ? text.arabic[index] : ""
        let isMemorized = memorizedAyahs.isMemorized(surahId: surah.id, ayah: ayahNumber)
        let showArabic = textLanguage != .english
        let showEnglish = textLanguage != .arabic || textLanguage == .memorized

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ayah \(ayahNumber)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if isMemorized {
                    Label("Memorized", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.green)
                }
            }

            if showArabic {
                Text(verse)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
            }

            if showEnglish, index < text.english.count {
                Text(text.english[index])
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isMemorized ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isMemorized ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .onTapGesture(count: 2) {
            toggleMemorizedAyah(at: index, totalAyahs: totalAyahs, in: surah)
        }
    }

    private func toggleMemorizedAyah(at index: Int, totalAyahs: Int, in surah: Surah) {
        let ayahNumber = index + 1
        memorizedAyahs.toggleMemorized(surahId: surah.id, ayah: ayahNumber)

        let memorizedCount = memorizedAyahs.memorizedCount(for: surah.id)
        let clampedTotal = max(totalAyahs, ayahNumber)
        let newState: HighlightState
        if memorizedCount == 0 {
            newState = .none
        } else if memorizedCount < clampedTotal {
            newState = .inProgress
        } else {
            newState = .memorized
        }

        withAnimation(.spring(duration: 0.25)) {
            highlights.setState(newState, for: surah.id)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet")
                .font(.largeTitle)
            Text("Choose a surah from the Surahs tab.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum SurahTextLanguage: String, CaseIterable, Identifiable {
    case arabic
    case english
    case both
    case memorized

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arabic: return "Arabic"
        case .english: return "English"
        case .both: return "Both"
        case .memorized: return "Memorized"
        }
    }
}

#Preview("Memorizer") {
    RootTabView()
        .environmentObject(AppNav())
        .environmentObject(ThemeManager())
        .environmentObject(AppPrefsStore())
        .environmentObject(HighlightStore())
        .environmentObject(MemorizedAyahStore())
        .environmentObject(MemorizerState())
}
