import Foundation

struct APIResponse: Codable {
    let err: Int
    let msg: String
    let data: [MusicSection]
}

struct MusicSection: Codable, Identifiable {
    let sectionType: String
    let viewType: String
    let title: String
    let link: String
    let sectionId: String
    let items: [Playlist]

    var id: String { title }
}

struct Playlist: Codable, Identifiable {
    let encodeId: String
    let title: String
    let thumbnail: String
    let sortDescription: String
    let artists: [Artist]?
    let artistsNames: String
    let thumbnailM: String

    var id: String { encodeId }

    enum CodingKeys: String, CodingKey {
        case encodeId, title, thumbnail, sortDescription
        case artists, artistsNames, thumbnailM
    }
}

struct Artist: Codable, Identifiable {
    let id: String
    let name: String
    let alias: String?
    let thumbnail: String?
    let thumbnailM: String?
    let totalFollow: Int?
}
