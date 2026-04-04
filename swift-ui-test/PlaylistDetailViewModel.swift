import Foundation

@Observable
class PlaylistDetailViewModel {
    var detail: PlaylistDetail?
    var isLoading = false
    var errorMessage: String?

    let seedPlaylist: Playlist

    init(playlist: Playlist) {
        self.seedPlaylist = playlist
    }

    var displayTitle: String {
        detail?.title ?? seedPlaylist.title
    }

    var displayArtworkURL: String {
        let detailURL = detail?.thumbnailM ?? ""
        return detailURL.isEmpty ? seedPlaylist.thumbnailM : detailURL
    }

    var displayArtistsText: String {
        let detailArtists = detail?.artistsNames ?? ""
        return detailArtists.isEmpty ? seedPlaylist.artistsNames : detailArtists
    }

    var displayDescription: String {
        let summary = detail?.summaryText ?? ""
        return summary.isEmpty ? seedPlaylist.sortDescription : summary
    }

    var displayArtists: [Artist] {
        detail?.artists ?? seedPlaylist.artists ?? []
    }

    var tracks: [PlaylistSong] {
        detail?.song?.items ?? []
    }

    var genreLabel: String? {
        detail?.genres?.first?.title ?? detail?.genres?.first?.name
    }

    func fetchDetailIfNeeded() async {
        guard detail == nil, !isLoading else { return }
        await fetchDetail()
    }

    func fetchDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await APIClient.shared.fetch(.playlistDetail(id: seedPlaylist.encodeId))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
