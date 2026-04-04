import Foundation

// MARK: - Artist Detail

struct ArtistDetail: Decodable, Identifiable {
    let id: String
    let name: String
    let alias: String?
    let thumbnail: String?
    let thumbnailM: String?
    let biography: String?
    let sortBiography: String?
    let cover: String?
    let national: String?
    let birthday: String?
    let realname: String?
    let totalFollow: Int?
    let sections: [ArtistSection]?
    let hasOA: Bool?
}

// MARK: - Artist Section

struct ArtistSection: Decodable, Identifiable {
    let sectionType: String?
    let sectionId: String?
    let title: String?
    let viewType: String?
    let link: String?
    let itemType: String?
    let songItems: [ArtistSongItem]
    let playlistItems: [Playlist]
    let videoItems: [VideoItem]
    let artistItems: [Artist]

    var id: String { sectionId ?? title ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case sectionType, sectionId, title, viewType, link, itemType, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sectionType = try? container.decode(String.self, forKey: .sectionType)
        sectionId = try? container.decode(String.self, forKey: .sectionId)
        title = try? container.decode(String.self, forKey: .title)
        viewType = try? container.decode(String.self, forKey: .viewType)
        link = try? container.decode(String.self, forKey: .link)
        itemType = try? container.decode(String.self, forKey: .itemType)

        switch sectionType {
        case "song":
            songItems = (try? container.decode([FailableDecodable<ArtistSongItem>].self, forKey: .items))?.compactMap(\.value) ?? []
            playlistItems = []
            videoItems = []
            artistItems = []
        case "playlist":
            playlistItems = (try? container.decode([FailableDecodable<Playlist>].self, forKey: .items))?.compactMap(\.value) ?? []
            songItems = []
            videoItems = []
            artistItems = []
        case "video":
            videoItems = (try? container.decode([FailableDecodable<VideoItem>].self, forKey: .items))?.compactMap(\.value) ?? []
            songItems = []
            playlistItems = []
            artistItems = []
        case "artist":
            artistItems = (try? container.decode([FailableDecodable<Artist>].self, forKey: .items))?.compactMap(\.value) ?? []
            songItems = []
            playlistItems = []
            videoItems = []
        default:
            songItems = []
            playlistItems = []
            videoItems = []
            artistItems = []
        }
    }
}

// MARK: - Artist Song Item

struct ArtistSongItem: Decodable, Identifiable {
    let encodeId: String
    let title: String
    let alias: String?
    let artistsNames: String?
    let artists: [Artist]?
    let thumbnail: String?
    let thumbnailM: String?
    let duration: Int?
    let releaseDate: Int?

    var id: String { encodeId }
}

// MARK: - Artist Songs Response

struct ArtistSongsData: Decodable {
    let items: [ArtistSongItem]?
    let total: Int?
    let hasMore: Bool?
}
