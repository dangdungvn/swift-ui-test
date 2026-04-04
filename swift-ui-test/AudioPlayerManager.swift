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

    func play(song: PlayableSong) async {
        if currentSong?.id == song.id, isPlaying {
            pause()
            return
        }

        currentSong = song
        currentSongInfo = nil
        currentLyric = nil
        isLoading = true
        isPlaying = false
        errorMessage = nil
        currentTime = 0
        duration = 0

        do {
            let streaming: SongStreamingData = try await APIClient.shared.fetch(.song(id: song.id))
            guard let urlString = streaming.bestURL,
                  let url = URL(string: urlString) else {
                errorMessage = "Khong tim thay link phat"
                isLoading = false
                return
            }

            let playerItem = AVPlayerItem(url: url)
            if player == nil {
                player = AVPlayer(playerItem: playerItem)
            } else {
                player?.replaceCurrentItem(with: playerItem)
            }
            installTimeObserverIfNeeded()
            player?.play()

            if let info: SongInfo = try? await APIClient.shared.fetch(.infoSong(id: song.id)) {
                currentSongInfo = info
                duration = Double(info.duration ?? 0)
                currentSong = PlayableSong(
                    id: info.encodeId,
                    title: info.title,
                    artistsNames: info.artistsNames ?? song.artistsNames,
                    thumbnail: info.thumbnailM ?? info.thumbnail ?? song.thumbnail
                )
            }

            if let lyric: SongLyric = try? await APIClient.shared.fetch(.lyric(id: song.id)) {
                currentLyric = lyric
            }
            isPlaying = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
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

        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
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
