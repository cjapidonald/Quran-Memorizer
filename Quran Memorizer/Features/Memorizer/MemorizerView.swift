import SwiftUI

struct MemorizerView: View {
    @EnvironmentObject private var nav: AppNav
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var prefs: AppPrefsStore
    @EnvironmentObject private var mem: MemorizerState
    @EnvironmentObject private var highlights: HighlightStore
    @EnvironmentObject private var memorizedAyahs: MemorizedAyahStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPlayerControls = false
    @State private var textLanguage: SurahTextLanguage = .both
    @State private var showFullscreen = false
    @State private var fullScreenSurah: Surah? = nil
    @State private var fullScreenText: SurahTextContent? = nil
    @State private var resumePlaybackAfterFullscreen = false

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
                ensureValidReadingTheme()
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
            .onChange(of: theme.themeStyle) { _, _ in
                ensureValidReadingTheme()
            }
            .onChange(of: colorScheme) { _, _ in
                ensureValidReadingTheme()
            }
        }
        .fullScreenCover(isPresented: $showFullscreen, onDismiss: {
            fullScreenSurah = nil
            fullScreenText = nil
            resumePlaybackAfterFullscreen = false
        }) {
            if let surah = fullScreenSurah, let text = fullScreenText {
                fullScreenReader(for: surah, text: text)
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

    private var availableReadingThemes: [ReadingTheme] {
        ReadingTheme.availableThemes(for: colorScheme)
    }

    private var readingPalette: ReadingThemePalette {
        theme.readingTheme.palette(for: colorScheme)
            ?? ReadingTheme.defaultTheme(for: colorScheme).palette(for: colorScheme)
            ?? ReadingTheme.standard.palette(for: .light)!
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
    private func sampleStatus(for surah: Surah) -> some View {
        switch mem.sampleAvailability {
        case .loading:
            HStack(spacing: 6) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7, anchor: .center)
                Text("Downloading \(surah.englishName) audio…")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        case .ready:
            Label("Offline audio ready – \(mem.selectedReciter.rawValue)", systemImage: "waveform")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .failed:
            Label("Couldn't download the audio. Check your connection.", systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(.red)
        case .none:
            Label("Tap Download to save this recitation for offline use.", systemImage: "arrow.down.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func downloadButton(for surah: Surah) -> some View {
        Button {
            mem.downloadCurrentSample()
        } label: {
            Label(
                mem.sampleAvailability == .ready
                    ? "Redownload \(surah.englishName)"
                    : "Download \(surah.englishName)",
                systemImage: "arrow.down.circle"
            )
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(mem.sampleAvailability == .loading)
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
                if mem.selectedReciter.onDemandResourceTag(for: surah.id) != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        downloadButton(for: surah)
                        sampleStatus(for: surah)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Label("Offline downloads are currently available for the first few surahs.", systemImage: "info.circle")
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
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                Text("Surah text")
                    .font(.headline)
                    .foregroundStyle(readingPalette.primaryTextColor)
                Spacer()
                Button {
                    fullScreenSurah = surah
                    fullScreenText = text
                    resumePlaybackAfterFullscreen = mem.isPlaying
                    showFullscreen = true
                } label: {
                    Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            surahTextBody(text, surah: surah, totalAyahs: totalAyahs, indices: indices)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(readingPalette.backgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(readingPalette.borderColor.opacity(0.4), lineWidth: 1)
        )
    }

    private func surahTextBody(_ text: SurahTextContent, surah: Surah, totalAyahs: Int, indices: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Language", selection: $textLanguage) {
                ForEach(SurahTextLanguage.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Reading background")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(readingPalette.secondaryTextColor)
                readingBackgroundSelector
            }

            Text("Double-tap an ayah to toggle its memorized status.")
                .font(.footnote)
                .foregroundStyle(readingPalette.secondaryTextColor)

            if textLanguage == .memorized && indices.isEmpty {
                Label("No ayahs memorized yet.", systemImage: "bookmark.slash")
                    .font(.footnote)
                    .foregroundStyle(readingPalette.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(readingPalette.cardGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(readingPalette.borderColor.opacity(0.35), lineWidth: 0.8)
                    )
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(indices, id: \.self) { index in
                        ayahCard(for: index, text: text, surah: surah, totalAyahs: totalAyahs)
                    }
                }
            }
        }
    }

    private var readingBackgroundSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableReadingThemes, id: \.self) { option in
                    let palette = option.palette(for: colorScheme)!
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            theme.readingTheme = option
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(palette.swatchGradient)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.accentColor.opacity(theme.readingTheme == option ? 0.9 : 0.4), lineWidth: theme.readingTheme == option ? 3 : 1)
                                )
                            Text(option.displayName)
                                .font(.caption2)
                                .foregroundStyle(theme.readingTheme == option ? palette.primaryTextColor : palette.secondaryTextColor)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(minWidth: 72)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.readingTheme == option ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func ensureValidReadingTheme() {
        let available = availableReadingThemes
        guard !available.isEmpty else { return }
        if !available.contains(theme.readingTheme) {
            let fallback = ReadingTheme.defaultTheme(for: colorScheme)
            if available.contains(fallback) {
                theme.readingTheme = fallback
            } else if let first = available.first {
                theme.readingTheme = first
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

        let indicator = VStack(spacing: 6) {
            Text("\(ayahNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(readingPalette.secondaryTextColor)

            if isMemorized {
                Image(systemName: "checkmark.seal.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
            }
        }

        return VStack(alignment: .leading, spacing: 8) {
            if showArabic {
                HStack(alignment: .top, spacing: 12) {
                    Spacer(minLength: 0)
                    Text(verse)
                        .font(.custom("KFGQPC Uthmanic Script HAFS", size: 28))
                        .foregroundStyle(readingPalette.primaryTextColor)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    indicator
                }
            }

            if showEnglish, index < text.english.count {
                if showArabic {
                    Text(text.english[index])
                        .font(.body)
                        .foregroundStyle(readingPalette.secondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        indicator
                        Text(text.english[index])
                            .font(.body)
                            .foregroundStyle(readingPalette.secondaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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

    @ViewBuilder
    private func fullScreenReader(for surah: Surah, text: SurahTextContent) -> some View {
        let totalAyahs = surah.ayahCount > 0 ? surah.ayahCount : text.arabic.count
        let indices = ayahIndices(for: text, surah: surah)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    surahTextBody(text, surah: surah, totalAyahs: totalAyahs, indices: indices)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(readingPalette.backgroundGradient.ignoresSafeArea())
            .navigationTitle(surah.englishName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showFullscreen = false }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
        }
        .onAppear {
            if resumePlaybackAfterFullscreen && !mem.isPlaying {
                mem.play()
            }
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
