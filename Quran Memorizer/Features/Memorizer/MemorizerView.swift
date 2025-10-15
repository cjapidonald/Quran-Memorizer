import SwiftUI

struct MemorizerView: View {
    @EnvironmentObject private var nav: AppNav
    @EnvironmentObject private var prefs: AppPrefsStore
    @EnvironmentObject private var mem: MemorizerState

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let s = nav.selectedSurah {
                    header(for: s)
                    timeline
                    controls
                } else {
                    emptyState
                }
                Spacer(minLength: 0)
            }
            .padding()
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
                }
            }
            .onChange(of: prefs.defaultReciter) { _, newValue in
                mem.selectedReciter = newValue
            }
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
            if s.id == 1 {
                sampleStatus(for: mem.sampleAvailability)
            } else {
                Label("Audio samples are currently provided for Surah Al-Fātiḥah.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
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

#Preview("Memorizer") {
    RootTabView()
        .environmentObject(AppNav())
        .environmentObject(ThemeManager())
        .environmentObject(AppPrefsStore())
        .environmentObject(HighlightStore())
        .environmentObject(MemorizerState())
}
