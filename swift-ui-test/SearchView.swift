import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var audioPlayer = AudioPlayerManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()
                contentLayer
            }
            .navigationTitle("Tim kiem")
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .navigationDestination(for: ArtistRoute.self) { route in
                ArtistView(artistName: route.name)
            }
        }
        .searchable(text: $viewModel.query, prompt: "Bai hat, nghe si, playlist...")
        .onChange(of: viewModel.query) {
            viewModel.onQueryChanged()
        }
    }

    @ViewBuilder
    private var contentLayer: some View {
        if viewModel.query.trimmingCharacters(in: .whitespaces).count < 2 {
            emptyState
        } else if viewModel.isLoading && !viewModel.hasResults {
            AppStatusView(
                systemImage: "magnifyingglass",
                title: "Dang tim kiem...",
                message: "Dang tim kiem '\(viewModel.query)'",
                style: .loading
            )
        } else if let error = viewModel.errorMessage, !viewModel.hasResults {
            AppStatusView(
                systemImage: "wifi.exclamationmark",
                title: "Khong the tim kiem",
                message: error,
                style: .error(actionTitle: "Thu lai") {
                    viewModel.onQueryChanged()
                }
            )
        } else if viewModel.hasResults {
            resultsList
        } else {
            AppStatusView(
                systemImage: "magnifyingglass",
                title: "Khong tim thay ket qua",
                message: "Thu tu khoa khac nhe.",
                style: .placeholder
            )
        }
    }

    private var emptyState: some View {
        AppStatusView(
            systemImage: "magnifyingglass",
            title: "Tim kiem",
            message: "Nhap tu khoa de tim bai hat, nghe si hoac playlist.",
            style: .placeholder
        )
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !viewModel.artists.isEmpty {
                    artistsSection
                }
                if !viewModel.songs.isEmpty {
                    songsSection
                }
                if !viewModel.videos.isEmpty {
                    videosSection
                }
                if !viewModel.playlists.isEmpty {
                    playlistsSection
                }
            }
            .padding(.bottom, 100)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: - Artists Section

    private var artistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Nghe si", detail: "\(viewModel.artists.count)")

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 12) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.artists) { artist in
                            NavigationLink(value: ArtistRoute(name: artist.alias ?? artist.name)) {
                                SearchArtistCard(artist: artist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Songs Section

    private var songsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Bai hat", detail: "\(viewModel.songs.count)")

            GlassEffectContainer(spacing: 10) {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.songs) { song in
                        SearchSongRow(song: song, audioPlayer: audioPlayer)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Playlists Section

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Playlist", detail: "\(viewModel.playlists.count)")

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 14) {
                    LazyHStack(spacing: 14) {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(value: playlist) {
                                HomePlaylistCard(playlist: playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Videos Section

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "MV", detail: "\(viewModel.videos.count)")

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 14) {
                    LazyHStack(spacing: 14) {
                        ForEach(viewModel.videos) { video in
                            SearchVideoCard(video: video)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Search Artist Card

struct SearchArtistCard: View {
    let artist: SearchArtist

    var body: some View {
        VStack(spacing: 8) {
            MediaArtworkView(url: artist.thumbnailM ?? artist.thumbnail ?? "", cornerRadius: 40, icon: "person.fill")
                .frame(width: 80, height: 80)
                .clipShape(.circle)

            VStack(spacing: 2) {
                Text(artist.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let followers = artist.totalFollow, followers > 0 {
                    Text(formatFollowers(followers))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 20))
    }

    private func formatFollowers(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Search Song Row

struct SearchSongRow: View {
    let song: SearchSong
    let audioPlayer: AudioPlayerManager

    var isCurrentSong: Bool {
        audioPlayer.currentSong?.id == song.id
    }

    var body: some View {
        Button {
            Task {
                await audioPlayer.play(song: PlayableSong(
                    id: song.encodeId,
                    title: song.title,
                    artistsNames: song.artistsNames ?? "",
                    thumbnail: song.thumbnailM ?? song.thumbnail ?? ""
                ))
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    MediaArtworkView(url: song.thumbnailM ?? song.thumbnail ?? "", cornerRadius: 12)
                        .frame(width: 50, height: 50)

                    if isCurrentSong {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(.black.opacity(0.4))
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isCurrentSong ? .purple : .white)
                        .lineLimit(1)

                    Text(song.artistsNames ?? "")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                }

                Spacer()

                if let duration = song.duration {
                    Text(formatDuration(duration))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}

// MARK: - Search Video Card

struct SearchVideoCard: View {
    let video: VideoItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                MediaArtworkView(url: video.thumbnailM ?? video.thumbnail ?? "", cornerRadius: 18)
                    .frame(width: 220, height: 124)

                Image(systemName: "play.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .glassEffect(.regular.tint(.white.opacity(0.08)).interactive(), in: .circle)
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(video.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(video.artistsNames ?? video.artist?.name ?? "")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 220, alignment: .leading)
        .padding(8)
        .glassEffect(.regular.tint(.white.opacity(0.04)).interactive(), in: .rect(cornerRadius: 24))
    }
}

// MARK: - Navigation Route

struct ArtistRoute: Hashable {
    let name: String
}
