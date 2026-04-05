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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if audioPlayer.currentSong != nil {
                VStack(spacing: 0) {
                    NowPlayingBar(audioPlayer: audioPlayer)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 22))
                        .padding(.horizontal, 16)

                    Color.clear
                        .frame(height: 56)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.25), value: audioPlayer.currentSong?.id)
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
                Button {
                    audioPlayer.presentSongDetail()
                } label: {
                    HStack(spacing: 10) {
                        MediaArtworkView(url: song.thumbnail, cornerRadius: 10)
                            .frame(width: 30, height: 30)

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
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Button {
                    audioPlayer.togglePlayPause()
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Button {
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .transaction { transaction in
                transaction.animation = nil
            }
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
