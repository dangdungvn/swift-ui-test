import Foundation

@Observable
class PlaylistDetailViewModel {
    var detail: PlaylistDetail?
    var isLoading = false
    var errorMessage: String?

    let seedPlaylist: Playlist
    private let baseURL = "https://real-apparently-wombat.ngrok-free.app/api/detailplaylist?id="

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
        guard let url = URL(string: "\(baseURL)\(seedPlaylist.encodeId)") else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PlaylistDetailAPIResponse.self, from: data)

            if response.err == 0 {
                detail = response.data
            } else {
                errorMessage = response.msg
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
