import AVFoundation
import Foundation

@MainActor
@Observable
class AudioPlayerManager {
    static let shared = AudioPlayerManager()

    var currentSong: PlayableSong?
    var currentSongInfo: SongInfo?
    var currentLyric: SongLyric?
    var isSongDetailPresented = false
    var isPlaying = false
    var isLoading = false
    var errorMessage: String?
    var currentTime: Double = 0
    var duration: Double = 0

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var pendingPlayRequestID: UUID?
    private var shouldPlayWhenReady = false
    private var playbackTask: Task<Void, Never>?

    private init() {
        setupAudioSession()
    }

    deinit {
        let token = MainActor.assumeIsolated { timeObserverToken }
        let p = MainActor.assumeIsolated { player }
        if let token {
            p?.removeTimeObserver(token)
        }
    }

    private func setupAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func play(song: PlayableSong) {
        let requestID = UUID()
        pendingPlayRequestID = requestID
        shouldPlayWhenReady = true

        playbackTask?.cancel()

        if currentSong?.id == song.id, isPlaying {
            pause()
            return
        }

        currentSong = song
        currentSongInfo = nil
        currentLyric = nil
        isLoading = true
        isPlaying = true
        errorMessage = nil
        currentTime = 0
        duration = 0

        playbackTask = Task { [weak self] in
            guard let self else { return }
            await self.loadSong(song, requestID: requestID)
        }
    }

    private func loadSong(_ song: PlayableSong, requestID: UUID) async {
        defer {
            if pendingPlayRequestID == requestID {
                isLoading = false
            }
        }

        do {
            let streaming: SongStreamingData = try await APIClient.shared.fetch(.song(id: song.id))
            guard pendingPlayRequestID == requestID, !Task.isCancelled else { return }

            guard let urlString = streaming.bestURL,
                  let url = URL(string: urlString) else {
                errorMessage = "Khong tim thay link phat"
                isLoading = false
                isPlaying = false
                return
            }

            let playerItem = AVPlayerItem(url: url)
            if player == nil {
                player = AVPlayer(playerItem: playerItem)
            } else {
                player?.replaceCurrentItem(with: playerItem)
            }
            installTimeObserverIfNeeded()
            if shouldPlayWhenReady {
                player?.play()
                isPlaying = true
            } else {
                player?.pause()
                isPlaying = false
            }

            async let infoTask: SongInfo? = try? APIClient.shared.fetch(.infoSong(id: song.id))
            async let lyricTask: SongLyric? = try? APIClient.shared.fetch(.lyric(id: song.id))

            if let info = await infoTask {
                guard pendingPlayRequestID == requestID, !Task.isCancelled else { return }
                currentSongInfo = info
                duration = Double(info.duration ?? 0)
                currentSong = PlayableSong(
                    id: info.encodeId,
                    title: info.title,
                    artistsNames: info.artistsNames ?? song.artistsNames,
                    thumbnail: info.thumbnailM ?? info.thumbnail ?? song.thumbnail
                )
            }

            if let lyric = await lyricTask {
                guard pendingPlayRequestID == requestID, !Task.isCancelled else { return }
                currentLyric = lyric
            }
            isPlaying = shouldPlayWhenReady
        } catch {
            guard pendingPlayRequestID == requestID, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            isPlaying = false
            isLoading = false
        }
    }

    func pause() {
        shouldPlayWhenReady = false
        player?.pause()
        isPlaying = false
    }

    func resume() {
        shouldPlayWhenReady = true
        player?.play()
        isPlaying = true
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        currentSong = nil
        currentSongInfo = nil
        currentLyric = nil
        isSongDetailPresented = false
        errorMessage = nil
        isLoading = false
        currentTime = 0
        duration = 0
        pendingPlayRequestID = nil
        shouldPlayWhenReady = false
    }

    func presentSongDetail() {
        guard currentSong != nil else { return }
        isSongDetailPresented = true
    }

    func dismissSongDetail() {
        isSongDetailPresented = false
    }

    func seek(to seconds: Double) {
        guard let player else { return }
        let bounded = min(max(seconds, 0), duration > 0 ? duration : seconds)
        currentTime = bounded
        let time = CMTime(seconds: bounded, preferredTimescale: 600)
        player.seek(to: time)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    private func installTimeObserverIfNeeded() {
        guard timeObserverToken == nil, let player else { return }

        let interval = CMTime(seconds: 0.01, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds.isFinite ? time.seconds : 0

                if self.duration <= 0,
                   let itemDuration = self.player?.currentItem?.duration.seconds,
                   itemDuration.isFinite,
                   itemDuration > 0 {
                    self.duration = itemDuration
                }
            }
        }
    }
}

// MARK: - Playable Song Protocol

struct PlayableSong: Equatable {
    let id: String
    let title: String
    let artistsNames: String
    let thumbnail: String

    static func == (lhs: PlayableSong, rhs: PlayableSong) -> Bool {
        lhs.id == rhs.id
    }
}
