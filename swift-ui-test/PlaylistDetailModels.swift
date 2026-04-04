import Foundation

struct PlaylistDetailAPIResponse: Codable {
    let err: Int
    let msg: String
    let data: PlaylistDetail
}

struct PlaylistDetail: Codable, Identifiable {
    let encodeId: String
    let title: String
    let thumbnail: String
    let sortDescription: String
    let description: String?
    let artists: [Artist]?
    let artistsNames: String
    let thumbnailM: String
    let distributor: String?
    let genres: [PlaylistGenre]?
    let song: PlaylistSongCollection?

    var id: String { encodeId }

    var summaryText: String {
        if let description, !description.isEmpty {
            return description
        }
        return sortDescription
    }
}

struct PlaylistGenre: Codable, Identifiable {
    let id: String
    let name: String
    let title: String?
    let alias: String?
    let link: String?
}

struct PlaylistSongCollection: Codable {
    let items: [PlaylistSong]
}

struct PlaylistSong: Codable, Identifiable {
    let encodeId: String
    let title: String
    let alias: String?
    let artistsNames: String
    let artists: [Artist]?
    let thumbnailM: String?
    let thumbnail: String?
    let duration: Int?
    let releaseDate: Int?

    var id: String { encodeId }
}
