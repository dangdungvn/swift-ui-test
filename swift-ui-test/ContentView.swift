import SwiftUI

struct ContentView: View {
    @State private var audioPlayer = AudioPlayerManager.shared

    var body: some View {
        TabView {
            Tab("Kham pha", systemImage: "music.note.house.fill") {
                HomeView()
            }
            Tab("Top 100", systemImage: "chart.bar.fill") {
                Top100View()
            }
            Tab(role: .search) {
                SearchView()
            }
            Tab("Thu vien", systemImage: "square.stack.fill") {
                LibraryPlaceholderView()
            }
        }
        .tint(.white)
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
        .tabViewBottomAccessory {
            if audioPlayer.currentSong != nil {
                NowPlayingBar(audioPlayer: audioPlayer)
                    .onTapGesture {
                        audioPlayer.presentSongDetail()
                    }
            }
        }
        .fullScreenCover(isPresented: $audioPlayer.isSongDetailPresented) {
            SongDetailView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Now Playing Bar

struct NowPlayingBar: View {
    let audioPlayer: AudioPlayerManager

    var body: some View {
        if let song = audioPlayer.currentSong {
            HStack(spacing: 10) {
                MediaArtworkView(url: song.thumbnail, cornerRadius: 8)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text(song.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(song.artistsNames)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    audioPlayer.togglePlayPause()
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                }

                Button {
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Placeholder Tabs

struct LibraryPlaceholderView: View {
    var body: some View {
        ZStack {
            AppBackdrop(colors: AppBackdrop.top100Colors)
            AppStatusView(
                systemImage: "square.stack.fill",
                title: "Thu vien",
                message: "Noi tap trung playlist da luu, history va nhac cua ban.",
                style: .placeholder
            )
        }
    }
}

// MARK: - Make Playlist Hashable for NavigationLink

extension Playlist: Hashable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.encodeId == rhs.encodeId
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(encodeId)
    }
}
