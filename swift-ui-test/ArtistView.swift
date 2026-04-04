import SwiftUI

struct ArtistView: View {
    @State private var viewModel: ArtistViewModel
    @State private var audioPlayer = AudioPlayerManager.shared

    init(artistName: String) {
        _viewModel = State(initialValue: ArtistViewModel(artistName: artistName))
    }

    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .task {
            if viewModel.detail == nil {
                await viewModel.fetchArtist()
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            AppBackdrop(colors: [
                Color(red: 0.03, green: 0.05, blue: 0.12),
                Color(red: 0.18, green: 0.10, blue: 0.24),
                Color(red: 0.05, green: 0.08, blue: 0.16),
                Color(red: 0.10, green: 0.08, blue: 0.20),
                Color(red: 0.22, green: 0.14, blue: 0.28),
                Color(red: 0.06, green: 0.10, blue: 0.18),
                .black,
                Color(red: 0.12, green: 0.06, blue: 0.20),
                .black
            ])

            AsyncImage(url: URL(string: viewModel.displayThumbnail)) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 60)
                        .opacity(0.35)
                        .scaleEffect(1.3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, .black.opacity(0.5), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                AppStatusView(
                    systemImage: "person.fill",
                    title: "Dang tai...",
                    message: "Dang lay thong tin nghe si.",
                    style: .loading
                )
            } else if let error = viewModel.errorMessage, viewModel.detail == nil {
                AppStatusView(
                    systemImage: "wifi.exclamationmark",
                    title: "Khong the tai",
                    message: error,
                    style: .error(actionTitle: "Thu lai") {
                        Task { await viewModel.fetchArtist() }
                    }
                )
            } else {
                mainContent
            }
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                actionSection
                if !viewModel.displayBio.isEmpty {
                    bioSection
                }
                songsSection
                if !viewModel.releases.isEmpty {
                    releasesSection
                }
                if !viewModel.videos.isEmpty {
                    videosSection
                }
                if !viewModel.relatedArtists.isEmpty {
                    relatedArtistsSection
                }
            }
            .containerRelativeFrame(.horizontal)
            .padding(.bottom, 100)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    // MARK: - Hero

    private var heroSection: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                MediaArtworkView(url: viewModel.displayThumbnail, cornerRadius: 70, icon: "person.fill")
                    .frame(width: 140, height: 140)
                    .clipShape(.circle)
                    .shadow(color: .purple.opacity(0.3), radius: 30, y: 10)
                    .glassEffect(.regular.tint(.white.opacity(0.04)), in: .circle)

                GlassPanel(cornerRadius: 22) {
                    VStack(spacing: 6) {
                        Text(viewModel.displayName)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        if viewModel.followCount > 0 {
                            Text(formatFollowers(viewModel.followCount) + " nguoi theo doi")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        if !viewModel.displayRealName.isEmpty || !viewModel.displayNational.isEmpty || !viewModel.displayBirthday.isEmpty {
                            artistMetaLine
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var artistMetaLine: some View {
        let values = [
            viewModel.displayRealName,
            viewModel.displayNational,
            viewModel.displayBirthday
        ].filter { !$0.isEmpty }

        if !values.isEmpty {
            Text(values.joined(separator: " • "))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(.white.opacity(0.06)).interactive(), in: .capsule)
        }
    }

    // MARK: - Action Buttons

    private var actionSection: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {} label: {
                    GlassActionButton(
                        title: "Theo doi",
                        systemImage: "person.badge.plus",
                        tint: Color(red: 0.34, green: 0.18, blue: 0.42).opacity(0.5)
                    )
                }

                Button {} label: {
                    GlassActionButton(title: "Phat nhac", systemImage: "play.fill", tint: nil)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Biography

    private var bioSection: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tieu su")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(cleanHTML(viewModel.displayBio))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineSpacing(4)
                    .lineLimit(6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Songs

    private var songsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(
                title: "Bai hat noi bat",
                detail: viewModel.songs.isEmpty ? nil : "\(viewModel.songs.count) bai"
            )

            if viewModel.songs.isEmpty {
                GlassPanel {
                    AppStatusView(
                        systemImage: "music.note",
                        title: "Chua co bai hat",
                        message: "Khong tim thay bai hat cua nghe si nay.",
                        style: .placeholder
                    )
                    .frame(height: 120)
                }
                .padding(.horizontal, 20)
            } else {
                GlassEffectContainer(spacing: 10) {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.songs) { song in
                            ArtistSongRow(song: song, audioPlayer: audioPlayer)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Albums

    private var releasesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Album / Playlist", detail: "\(viewModel.releases.count)")

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 14) {
                    LazyHStack(spacing: 14) {
                        ForEach(viewModel.releases) { playlist in
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

    private var relatedArtistsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: "Ban co the thich", detail: "\(viewModel.relatedArtists.count)")

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 12) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.relatedArtists) { artist in
                            NavigationLink(value: ArtistRoute(name: artist.alias ?? artist.name)) {
                                SearchArtistCard(artist: SearchArtist(
                                    id: artist.id,
                                    name: artist.name,
                                    alias: artist.alias,
                                    thumbnail: artist.thumbnail,
                                    thumbnailM: artist.thumbnailM,
                                    totalFollow: artist.totalFollow
                                ))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatFollowers(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func cleanHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

// MARK: - Artist Song Row

struct ArtistSongRow: View {
    let song: ArtistSongItem
    let audioPlayer: AudioPlayerManager

    var isCurrentSong: Bool {
        audioPlayer.currentSong?.id == song.encodeId
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
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }
}
