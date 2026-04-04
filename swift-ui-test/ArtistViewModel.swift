import Foundation

@Observable
class ArtistViewModel {
    var detail: ArtistDetail?
    var songs: [ArtistSongItem] = []
    var releases: [Playlist] = []
    var videos: [VideoItem] = []
    var relatedArtists: [Artist] = []
    var isLoading = false
    var errorMessage: String?
    private let artistName: String

    init(artistName: String) {
        self.artistName = artistName
    }

    var displayName: String { detail?.name ?? artistName }
    var displayBio: String { detail?.biography ?? detail?.sortBiography ?? "" }
    var displayThumbnail: String { detail?.thumbnailM ?? detail?.thumbnail ?? "" }
    var followCount: Int { detail?.totalFollow ?? 0 }
    var displayNational: String { detail?.national ?? "" }
    var displayRealName: String { detail?.realname ?? "" }
    var displayBirthday: String { detail?.birthday ?? "" }

    func fetchArtist() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            detail = try await APIClient.shared.fetch(.artist(name: artistName))
            applySections()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applySections() {
        guard let sections = detail?.sections else {
            songs = []
            releases = []
            videos = []
            relatedArtists = []
            return
        }

        songs = sections.first(where: {
            $0.sectionType == "song" || $0.sectionId == "aSongs"
        })?.songItems ?? []

        releases = sections
            .filter { $0.sectionType == "playlist" }
            .flatMap(\.playlistItems)

        videos = sections
            .filter { $0.sectionType == "video" }
            .flatMap(\.videoItems)

        relatedArtists = sections
            .filter { $0.sectionType == "artist" }
            .flatMap(\.artistItems)
    }
}
