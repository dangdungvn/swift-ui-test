import SwiftUI

// MARK: - Top 100 Main View

struct Top100View: View {
    @State private var viewModel = Top100ViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    mainContent
                }
            }
            .task {
                if viewModel.sections.isEmpty {
                    await viewModel.fetchTop100()
                }
            }
            .navigationDestination(for: Playlist.self) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
        }
    }

    private var backgroundGradient: some View {
        AppBackdrop(colors: AppBackdrop.top100Colors)
    }

    private var loadingView: some View {
        AppStatusView(
            systemImage: "chart.bar",
            title: "Dang tai du lieu...",
            message: "Dang cap nhat bang xep hang noi bat.",
            style: .loading
        )
    }

    private func errorView(_ message: String) -> some View {
        AppStatusView(
            systemImage: "wifi.exclamationmark",
            title: "Khong the ket noi",
            message: message,
            style: .error(actionTitle: "Thu lai") {
                Task { await viewModel.fetchTop100() }
            }
        )
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerView

                if let featured = viewModel.featuredSection {
                    Top100SliderSection(section: featured)
                }

                ForEach(viewModel.listSections) { section in
                    Top100GridSection(section: section)
                }
            }
            .padding(.bottom, 100)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private var headerView: some View {
        AppScreenHeader(
            eyebrow: "Chart",
            title: "Top 100",
            subtitle: "Nhung playlist thinh hanh nhat"
        )
    }
}

// MARK: - Slider Section

struct Top100SliderSection: View {
    let section: MusicSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppSectionHeader(title: section.title, detail: nil)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(section.items) { playlist in
                        NavigationLink(value: playlist) {
                            Top100FeaturedCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

struct Top100FeaturedCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                MediaArtworkView(url: playlist.thumbnailM, cornerRadius: 28)
                    .aspectRatio(1, contentMode: .fill)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.18), .black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 10) {
                    GlassBadge("Featured", systemImage: "sparkles", tint: Color(red: 0.42, green: 0.15, blue: 0.34).opacity(0.45))

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2, reservesSpace: true)
                        Text(playlist.artistsNames)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .padding(18)
            }
            .frame(width: 280, height: 280)
        }
    }
}

// MARK: - Grid Section

struct Top100GridSection: View {
    let section: MusicSection

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppSectionHeader(title: section.title, detail: "Tat ca")

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(section.items) { playlist in
                    NavigationLink(value: playlist) {
                        Top100GridCard(playlist: playlist)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct Top100GridCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                MediaArtworkView(url: playlist.thumbnailM, cornerRadius: 20)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)

                GlassBadge("TOP 100", systemImage: "music.note.list", tint: Color(red: 0.36, green: 0.14, blue: 0.38).opacity(0.5))
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2, reservesSpace: true)
                Text(playlist.artists?.prefix(2).map(\.name).joined(separator: ", ") ?? playlist.artistsNames)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(.top, 8)
        }
    }
}
