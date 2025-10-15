import Foundation
import Combine

final class MemorizerState: ObservableObject {
    @Published var selectedSurah: Surah? = nil
    @Published var selectedReciter: Reciter = .saadAlGhamdi

    @Published var isPlaying: Bool = false
    @Published var isLooping: Bool = false
    @Published var duration: TimeInterval = 600
    @Published var currentTime: TimeInterval = 0

    @Published var loopStart: TimeInterval = 0
    @Published var loopEnd: TimeInterval = 30

    private var timer: Timer?

    func play() {
        guard !isPlaying else { return }
        isPlaying = true
        startTimer()
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
    }

    func togglePlay() { isPlaying ? pause() : play() }

    func seek(to t: TimeInterval) {
        currentTime = max(0, min(duration, t))
    }

    func setLoop(start: TimeInterval? = nil, end: TimeInterval? = nil) {
        if let s = start { loopStart = max(0, min(s, duration)) }
        if let e = end   { loopEnd   = max(loopStart, min(e, duration)) }
        if loopEnd - loopStart < 1 { loopEnd = min(duration, loopStart + 1) } // min 1s
        if currentTime < loopStart || currentTime > loopEnd { currentTime = loopStart }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            var next = self.currentTime + 0.05
            if self.isLooping {
                if next > self.loopEnd {
                    next = self.loopStart
                }
            }
            if next >= self.duration {
                next = self.isLooping ? self.loopStart : self.duration
                if !self.isLooping { self.pause() }
            }
            self.currentTime = next
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
}
