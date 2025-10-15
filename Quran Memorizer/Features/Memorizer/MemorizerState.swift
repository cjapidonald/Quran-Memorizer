import Foundation
import Combine
import AVFoundation
import class Foundation.NSBundleResourceRequest
#if canImport(AVFAudio)
import AVFAudio
#endif

@MainActor
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
    private var resourceTask: Task<Void, Never>?
    private var resourceRequest: NSBundleResourceRequest?

    func play() {
        guard !isPlaying else { return }
        isPlaying = true

        if player != nil {
            configureAudioSession()
            seek(to: loopStart)
        } else {
            seek(to: loopStart)
            startTimer()
        }
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
        let previousStart = loopStart

        if let s = start { loopStart = max(0, min(s, duration)) }
        if let e = end   { loopEnd   = max(loopStart, min(e, duration)) }
        if loopEnd - loopStart < 1 { loopEnd = min(duration, loopStart + 1) } // min 1s

        let startChanged = loopStart != previousStart
        let outOfRange = currentTime < loopStart || currentTime > loopEnd

        if startChanged || outOfRange || isLooping {
            seek(to: loopStart)
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
            } else if next >= self.loopEnd {
                next = self.loopEnd
                self.pause()
                self.currentTime = next
                return
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
        unloadPlayer()
        resourceTask?.cancel()
        resourceTask = nil
        releaseResourceRequest()

        guard let surah = selectedSurah else {
            resetForSimulation()
            sampleAvailability = .none
            return
        }

        sampleAvailability = .loading
        let reciter = selectedReciter
        resourceTask = Task { [weak self] in
            await self?.fetchSample(for: surah, reciter: reciter)
        }
    }

    private func resetForSimulation() {
        unloadPlayer()
        releaseResourceRequest()
        duration = 600
        currentTime = 0
        loopStart = 0
        loopEnd = 30
    }

    private func loadSample(from url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        currentTime = 0

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if self.currentTime >= self.loopEnd {
                if self.isLooping {
                    self.seek(to: self.loopStart)
                } else {
                    self.pause()
                    self.seek(to: self.loopEnd)
                }
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
                    let asset = item.asset
                    Task { [weak self] in
                        guard let self = self else { return }
                        let durationTime: CMTime
                        if #available(iOS 16.0, *) {
                            if let loadedDuration = try? await asset.load(.duration) {
                                durationTime = loadedDuration
                            } else {
                                durationTime = asset.duration
                            }
                        } else {
                            durationTime = asset.duration
                        }

                        let seconds = CMTimeGetSeconds(durationTime)
                        await MainActor.run {
                            self.duration = seconds.isFinite ? max(1, seconds) : 600
                            self.loopStart = 0
                            self.loopEnd = min(30, self.duration)
                            self.sampleAvailability = .ready
                        }
                    }
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

    private func releaseResourceRequest() {
        resourceRequest?.endAccessingResources()
        resourceRequest = nil
    }

    private func fetchSample(for surah: Surah, reciter: Reciter) async {
        defer { resourceTask = nil }

        var acquiredRequest: NSBundleResourceRequest?

        if let tag = reciter.onDemandResourceTag(for: surah.id) {
            let request = NSBundleResourceRequest(tags: [tag])
            request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            do {
                try await request.beginAccessingResources()
            } catch {
                request.endAccessingResources()
                if error is CancellationError {
                    return
                }
                resetForSimulation()
                sampleAvailability = .failed
                return
            }

            if Task.isCancelled {
                request.endAccessingResources()
                return
            }

            acquiredRequest = request
            resourceRequest = request
        }

        guard let url = reciter.sampleRecitation(for: surah) else {
            acquiredRequest?.endAccessingResources()
            if resourceRequest === acquiredRequest {
                resourceRequest = nil
            }
            resetForSimulation()
            sampleAvailability = surah.id == 1 ? .failed : .none
            return
        }

        if reciter.onDemandResourceTag(for: surah.id) != nil && !url.isFileURL {
            acquiredRequest?.endAccessingResources()
            if resourceRequest === acquiredRequest {
                resourceRequest = nil
            }
            resetForSimulation()
            sampleAvailability = .failed
            return
        }

        loadSample(from: url)
    }

    private func configureAudioSession() {
        #if canImport(AVFAudio)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
    }

    deinit {
        resourceTask?.cancel()
        releaseResourceRequest()
        unloadPlayer()
    }
}
