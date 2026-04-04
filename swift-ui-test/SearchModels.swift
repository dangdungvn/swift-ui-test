import Foundation

// MARK: - Search Result

struct SearchResult: Codable {
    let artists: [SearchArtist]?
    let songs: [SearchSong]?
    let videos: [VideoItem]?
    let playlists: [Playlist]?
    let top: SearchTopResult?
    let counter: SearchCounter?
    let sectionId: String?
}

// MARK: - Search Song

struct SearchSong: Codable, Identifiable {
    let encodeId: String
    let title: String
    let alias: String?
    let artistsNames: String?
    let artists: [Artist]?
    let thumbnail: String?
    let thumbnailM: String?
    let duration: Int?

    var id: String { encodeId }
}

// MARK: - Search Artist

struct SearchArtist: Codable, Identifiable {
    let id: String
    let name: String
    let alias: String?
    let thumbnail: String?
    let thumbnailM: String?
    let totalFollow: Int?
}

// MARK: - Video

struct VideoItem: Codable, Identifiable {
    let encodeId: String
    let title: String
    let alias: String?
    let artistsNames: String?
    let artists: [Artist]?
    let thumbnail: String?
    let thumbnailM: String?
    let duration: Int?
    let artist: VideoArtist?

    var id: String { encodeId }
}

struct VideoArtist: Codable {
    let id: String?
    let name: String?
    let alias: String?
    let thumbnail: String?
}

// MARK: - Counter

struct SearchCounter: Codable {
    let song: Int?
    let artist: Int?
    let playlist: Int?
    let video: Int?
}

// MARK: - Search Top Result

struct SearchTopResult: Codable {
    let objectType: String?
    let id: String?
    let name: String?
    let title: String?
    let alias: String?
    let thumbnail: String?
    let thumbnailM: String?
    let artistsNames: String?
}
