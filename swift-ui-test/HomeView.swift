import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                if viewModel.isLoading && viewModel.sections.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.sections.isEmpty {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .task {
                if viewModel.sections.isEmpty {
                    await viewModel.fetchHome()
                }
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
            .navigationDestination(for: ArtistRoute.self) { route in
                ArtistView(artistName: route.name)
            }
        }
    }

    private var loadingView: some View {
        AppStatusView(
            systemImage: "music.note.house",
            title: "Dang tai...",
            message: "Dang lay danh sach goi y cho ban.",
            style: .loading
        )
    }

    private func errorView(_ message: String) -> some View {
        AppStatusView(
            systemImage: "wifi.exclamationmark",
            title: "Khong the ket noi",
            message: message,
            style: .error(actionTitle: "Thu lai") {
                Task { await viewModel.fetchHome() }
            }
        )
    }

    private var mainContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                AppScreenHeader(
                    eyebrow: "For you",
                    title: "Xin chao!",
                    subtitle: "Hom nay ban muon nghe gi?"
                )

                ForEach(viewModel.displayableSections) { section in
                    HomeSectionRouter(section: section)
                }

                if viewModel.hasMore {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .task(id: viewModel.currentPage) {
                            await viewModel.loadMoreIfNeeded()
                        }
                }
            }
            .padding(.bottom, 100)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}

// MARK: - Section Router

struct HomeSectionRouter: View {
    let section: HomeSection

    var body: some View {
        switch section.sectionType {
        case "quickPlay":
            QuickPlaySectionView(items: section.quickPlayItems)
        case "playlist":
            HomePlaylistSectionView(section: section)
        case "newRelease":
            if let data = section.newReleaseItems {
                NewReleaseSectionView(title: section.title, data: data)
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Quick Play Section

struct QuickPlaySectionView: View {
    let items: [QuickPlayItem]

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(items.prefix(8)) { item in
                    QuickPlayCard(item: item)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct QuickPlayCard: View {
    let item: QuickPlayItem

    var body: some View {
        HStack(spacing: 10) {
            MediaArtworkView(url: item.thumbnail, cornerRadius: 10)
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(.white.opacity(0.06)).interactive(), in: .rect(cornerRadius: 14))
    }
}


// MARK: - Playlist Section (Horizontal Slider)

struct HomePlaylistSectionView: View {
    let section: HomeSection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: section.title, detail: section.link.isEmpty ? nil : "Tat ca")

            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 14) {
                    LazyHStack(spacing: 14) {
                        ForEach(section.playlistItems) { playlist in
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
}

struct HomePlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                MediaArtworkView(url: playlist.thumbnailM, cornerRadius: 20)
                    .aspectRatio(1, contentMode: .fill)

                GlassBadge("Playlist", systemImage: "music.note.list", tint: Color(red: 0.37, green: 0.18, blue: 0.45).opacity(0.45))
                    .padding(10)
            }
            .frame(width: 160, height: 160)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2, reservesSpace: true)
                Text(playlist.artistsNames)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(.top, 8)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 18))
            .frame(width: 160, alignment: .leading)
        }
        .padding(8)
        .glassEffect(.regular.tint(.white.opacity(0.04)).interactive(), in: .rect(cornerRadius: 28))
        .contentShape(.rect(cornerRadius: 28))
    }
}

// MARK: - New Release Section

struct NewReleaseSectionView: View {
    let title: String
    let data: NewReleaseData
    @State private var selectedTab = 0

    private var currentSongs: [NewReleaseSong] {
        switch selectedTab {
        case 0: return data.all ?? []
        case 1: return data.vPop ?? []
        case 2: return data.others ?? []
        default: return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppSectionHeader(title: title.isEmpty ? "Moi Phat Hanh" : title, detail: nil)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    TabPill(label: "Tat ca", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabPill(label: "Viet Nam", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabPill(label: "Quoc te", isSelected: selectedTab == 2) { selectedTab = 2 }
                }
            }
            .padding(.horizontal, 20)

            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(currentSongs.prefix(8)) { song in
                        NewReleaseSongRow(song: song)
                    }
                }
            }
            .padding(.horizontal, 20)
            .animation(.smooth, value: selectedTab)
        }
    }
}

struct TabPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .contentShape(Capsule())
        }
        .glassEffect(
            isSelected
                ? .regular.tint(Color(red: 0.35, green: 0.20, blue: 0.45).opacity(0.55)).interactive()
                : .regular.tint(.white.opacity(0.06)).interactive(),
            in: .capsule
        )
    }
}

struct NewReleaseSongRow: View {
    let song: NewReleaseSong
    var audioPlayer = AudioPlayerManager.shared

    private var isCurrentSong: Bool {
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

                    if let releaseDate = song.releaseDate {
                        Text(releaseDateText(from: releaseDate))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Spacer()

                Image(systemName: isCurrentSong && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(isCurrentSong ? 0.8 : 0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 18))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func releaseDateText(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}
