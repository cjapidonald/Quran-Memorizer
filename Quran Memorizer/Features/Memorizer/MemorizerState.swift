import Foundation
import Combine
import AVFoundation
#if canImport(AVFAudio)
import AVFAudio
#endif

final class MemorizerState: ObservableObject {
    enum SampleAvailability: Equatable { case none, loading, ready, failed }

    @Published var selectedSurah: Surah? = nil {
        didSet {
            if selectedSurah?.id != oldValue?.id {
                prepareForCurrentSelection()
            }
        }
    }
    @Published var selectedReciter: Reciter = .saadAlGhamdi {
        didSet {
            if selectedReciter != oldValue {
                prepareForCurrentSelection()
            }
        }
    }

    @Published var isPlaying: Bool = false
    @Published var isLooping: Bool = false
    @Published var duration: TimeInterval = 600
    @Published var currentTime: TimeInterval = 0

    @Published var loopStart: TimeInterval = 0
    @Published var loopEnd: TimeInterval = 30

    @Published private(set) var sampleAvailability: SampleAvailability = .none

    private var timer: Timer?
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var playbackFinishedObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    func play() {
        guard !isPlaying else { return }
        if let player {
            configureAudioSession()
            if isLooping && currentTime >= loopEnd {
                seek(to: loopStart)
            }
            player.play()
        } else {
            startTimer()
        }
        isPlaying = true
    }

    func pause() {
        if isPlaying { player?.pause() }
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func togglePlay() { isPlaying ? pause() : play() }

    func seek(to t: TimeInterval) {
        let clamped = max(0, min(duration, t))
        currentTime = clamped
        if let player {
            let cmTime = CMTime(seconds: clamped, preferredTimescale: 600)
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                guard let self = self, self.isPlaying else { return }
                self.player?.play()
            }
        }
    }

    func setLoop(start: TimeInterval? = nil, end: TimeInterval? = nil) {
        if let s = start { loopStart = max(0, min(s, duration)) }
        if let e = end   { loopEnd   = max(loopStart, min(e, duration)) }
        if loopEnd - loopStart < 1 { loopEnd = min(duration, loopStart + 1) } // min 1s
        if currentTime < loopStart || currentTime > loopEnd { currentTime = loopStart }
        if isLooping, let player {
            let cmTime = CMTime(seconds: loopStart, preferredTimescale: 600)
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
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

    private func prepareForCurrentSelection() {
        pause()
        guard let surah = selectedSurah else {
            resetForSimulation()
            sampleAvailability = .none
            return
        }

        guard let url = selectedReciter.sampleRecitation(for: surah) else {
            resetForSimulation()
            sampleAvailability = surah.id == 1 ? .failed : .none
            return
        }

        sampleAvailability = .loading
        loadSample(from: url)
    }

    private func resetForSimulation() {
        unloadPlayer()
        duration = 600
        currentTime = 0
        loopStart = 0
        loopEnd = 30
    }

    private func loadSample(from url: URL) {
        unloadPlayer()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        currentTime = 0

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if self.isLooping && self.currentTime >= self.loopEnd {
                self.seek(to: self.loopStart)
            }
        }

        playbackFinishedObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            if self.isLooping {
                self.seek(to: self.loopStart)
                if self.isPlaying { self.player?.play() }
            } else {
                self.pause()
            }
        }

        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .readyToPlay:
                    let seconds = CMTimeGetSeconds(item.asset.duration)
                    self.duration = seconds.isFinite ? max(1, seconds) : 600
                    self.loopStart = 0
                    self.loopEnd = min(30, self.duration)
                    self.sampleAvailability = .ready
                case .failed:
                    self.sampleAvailability = .failed
                    self.resetForSimulation()
                default:
                    break
                }
            }
            .store(in: &self.cancellables)
    }

    private func unloadPlayer() {
        timer?.invalidate()
        timer = nil
        if let observer = playbackFinishedObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackFinishedObserver = nil
        }
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
        cancellables.removeAll()
    }

    private func configureAudioSession() {
        #if canImport(AVFAudio)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
    }

    deinit {
        unloadPlayer()
    }
}
