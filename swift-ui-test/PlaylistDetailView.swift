import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @State private var viewModel: PlaylistDetailViewModel

    init(playlist: Playlist) {
        self.playlist = playlist
        _viewModel = State(initialValue: PlaylistDetailViewModel(playlist: playlist))
    }

    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .task {
            await viewModel.fetchDetailIfNeeded()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            AppBackdrop(colors: [
                Color(red: 0.02, green: 0.04, blue: 0.09),
                Color(red: 0.16, green: 0.14, blue: 0.24),
                Color(red: 0.03, green: 0.09, blue: 0.18),
                Color(red: 0.08, green: 0.10, blue: 0.20),
                Color(red: 0.24, green: 0.12, blue: 0.26),
                Color(red: 0.07, green: 0.08, blue: 0.17),
                .black,
                Color(red: 0.10, green: 0.08, blue: 0.18),
                .black
            ])

            AsyncImage(url: URL(string: viewModel.displayArtworkURL)) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 60)
                        .opacity(0.4)
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

    private var contentLayer: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                actionButtons
                if let errorMessage = viewModel.errorMessage {
                    inlineErrorView(errorMessage)
                }
                descriptionSection
                songsSection
                artistsSection
            }
            .containerRelativeFrame(.horizontal)
            .padding(.bottom, 100)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private var heroSection: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                ZStack(alignment: .topLeading) {
                    MediaArtworkView(url: viewModel.displayArtworkURL, cornerRadius: 30)
                        .aspectRatio(1, contentMode: .fill)
                        .glassEffect(.regular.tint(.white.opacity(0.04)).interactive(), in: .rect(cornerRadius: 30))

                    GlassBadge("Playlist", systemImage: "music.note.list", tint: Color(red: 0.33, green: 0.18, blue: 0.42).opacity(0.45))
                        .padding(14)
                }
                .frame(width: 260, height: 260)
                .shadow(color: .purple.opacity(0.3), radius: 30, y: 15)

                GlassPanel(cornerRadius: 26) {
                    VStack(spacing: 6) {
                        Text(viewModel.displayTitle)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)

                        Text(viewModel.displayArtistsText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if let genreLabel = viewModel.genreLabel, !genreLabel.isEmpty {
                            Text(genreLabel)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.82))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .glassEffect(.regular.tint(.white.opacity(0.06)).interactive(), in: .capsule)
                                .padding(.top, 4)
                        } else {
                            Text("Duoc chon loc cho bua nghe hien tai")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.82))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .glassEffect(.regular.tint(.white.opacity(0.06)).interactive(), in: .capsule)
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

    private var actionButtons: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                } label: {
                    GlassActionButton(title: "Phat", systemImage: "play.fill", tint: Color(red: 0.34, green: 0.18, blue: 0.42).opacity(0.5))
                }

                Button {
                } label: {
                    GlassActionButton(title: "Tron bai", systemImage: "shuffle", tint: nil)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func inlineErrorView(_ message: String) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Khong tai duoc chi tiet day du")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))

                Button("Thu lai") {
                    Task {
                        await viewModel.fetchDetail()
                    }
                }
                .buttonStyle(.glass)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    private var descriptionSection: some View {
        Group {
            let description = viewModel.displayDescription
            if !description.isEmpty {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gioi thieu")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var songsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(
                title: "Danh sach bai hat",
                detail: viewModel.tracks.isEmpty ? nil : "\(viewModel.tracks.count) bai"
            )

            if viewModel.isLoading && viewModel.tracks.isEmpty {
                GlassPanel {
                    AppStatusView(
                        systemImage: "music.note.list",
                        title: "Dang tai bai hat...",
                        message: "Dang lay tracklist cua playlist.",
                        style: .loading
                    )
                    .frame(height: 140)
                }
                .padding(.horizontal, 20)
            } else if viewModel.tracks.isEmpty {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chua co danh sach bai hat")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Endpoint da tra ve metadata, nhung khong co track item de hien thi.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
            } else {
                GlassEffectContainer(spacing: 10) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, song in
                            PlaylistSongRow(song: song, index: index + 1)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var artistsSection: some View {
        Group {
            let artists = viewModel.displayArtists
            if !artists.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    AppSectionHeader(title: "Nghe si", detail: nil)

                    ScrollView(.horizontal, showsIndicators: false) {
                        GlassEffectContainer(spacing: 12) {
                            LazyHStack(spacing: 12) {
                                ForEach(artists) { artist in
                                    ArtistChipView(artist: artist)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }
}

struct PlaylistSongRow: View {
    let song: PlaylistSong
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(String(format: "%02d", index))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: 26, alignment: .leading)

            MediaArtworkView(url: song.thumbnailM ?? song.thumbnail ?? "", cornerRadius: 12)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(song.artistsNames)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let duration = song.duration {
                        Text(formatDuration(duration))
                    }

                    if let releaseDate = song.releaseDate {
                        Text(releaseDateText(from: releaseDate))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.38))
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
                .frame(width: 30, height: 30)
                .glassEffect(.regular.tint(.white.opacity(0.04)).interactive(), in: .circle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.white.opacity(0.05)), in: .rect(cornerRadius: 18))
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private func releaseDateText(from timestamp: Int) -> String {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
            .formatted(.dateTime.day().month(.abbreviated))
    }
}

struct ArtistChipView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 10) {
            MediaArtworkView(url: artist.thumbnailM ?? "", cornerRadius: 20, icon: "person.fill")
                .frame(width: 40, height: 40)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let followers = artist.totalFollow, followers > 0 {
                    Text(formatFollowers(followers))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.trailing, 14)
        .padding(.leading, 4)
        .padding(.vertical, 4)
        .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .capsule)
    }

    private func formatFollowers(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM followers", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK followers", Double(count) / 1_000)
        }
        return "\(count) followers"
    }
}

#Preview {
    NavigationStack {
        PlaylistDetailView(playlist: Playlist(
            encodeId: "ZWZB969E",
            title: "Top 100 Nhac Tre Hay Nhat",
            thumbnail: "",
            sortDescription: "Top 100 Nhac Tre la danh sach 100 ca khuc hot nhat hien tai.",
            artists: [
                Artist(id: "1", name: "Quang Hung MasterD", alias: nil, thumbnail: nil, thumbnailM: nil, totalFollow: 234770),
                Artist(id: "2", name: "Tang Duy Tan", alias: nil, thumbnail: nil, thumbnailM: nil, totalFollow: 119181)
            ],
            artistsNames: "Nhieu nghe si",
            thumbnailM: ""
        ))
    }
}
