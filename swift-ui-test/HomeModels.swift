import Foundation

// MARK: - Home Data

struct HomeData: Codable {
    let items: [HomeSection]
    let hasMore: Bool?
    let total: Int?
}

// MARK: - Home Section (flexible decoding)

struct HomeSection: Identifiable, Codable {
    let sectionType: String
    let sectionId: String
    let title: String
    let viewType: String
    let link: String

    // For playlist / banner / quickPlay sections
    let playlistItems: [Playlist]
    let bannerItems: [Banner]
    let quickPlayItems: [QuickPlayItem]

    // For newRelease
    let newReleaseItems: NewReleaseData?

    var id: String {
        if !sectionId.isEmpty { return sectionId }
        if !title.isEmpty { return title }
        return sectionType + UUID().uuidString
    }

    var isDisplayable: Bool {
        switch sectionType {
        case "playlist": return !playlistItems.isEmpty
        case "banner": return !bannerItems.isEmpty
        case "quickPlay": return !quickPlayItems.isEmpty
        case "newRelease": return newReleaseItems != nil
        default: return false
        }
    }

    enum CodingKeys: String, CodingKey {
        case sectionType, sectionId, title, viewType, link, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sectionType = (try? container.decode(String.self, forKey: .sectionType)) ?? ""
        sectionId = (try? container.decode(String.self, forKey: .sectionId)) ?? ""
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        viewType = (try? container.decode(String.self, forKey: .viewType)) ?? ""
        link = (try? container.decode(String.self, forKey: .link)) ?? ""

        switch sectionType {
        case "playlist":
            playlistItems = (try? container.decode([FailableDecodable<Playlist>].self, forKey: .items))?.compactMap(\.value) ?? []
            bannerItems = []
            quickPlayItems = []
            newReleaseItems = nil
        case "banner":
            bannerItems = (try? container.decode([FailableDecodable<Banner>].self, forKey: .items))?.compactMap(\.value) ?? []
            playlistItems = []
            quickPlayItems = []
            newReleaseItems = nil
        case "quickPlay":
            quickPlayItems = (try? container.decode([FailableDecodable<QuickPlayItem>].self, forKey: .items))?.compactMap(\.value) ?? []
            playlistItems = []
            bannerItems = []
            newReleaseItems = nil
        case "newRelease":
            newReleaseItems = try? container.decode(NewReleaseData.self, forKey: .items)
            playlistItems = []
            bannerItems = []
            quickPlayItems = []
        default:
            playlistItems = []
            bannerItems = []
            quickPlayItems = []
            newReleaseItems = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sectionType, forKey: .sectionType)
        try container.encode(sectionId, forKey: .sectionId)
        try container.encode(title, forKey: .title)
        try container.encode(viewType, forKey: .viewType)
        try container.encode(link, forKey: .link)
    }
}

// MARK: - Banner

struct Banner: Codable, Identifiable {
    let banner: String
    let cover: String
    let encodeId: String?
    let link: String?
    let title: String?
    let description: String?
    let type: Int?

    var id: String { encodeId ?? banner }
}

// MARK: - Quick Play Item

struct QuickPlayItem: Codable, Identifiable {
    let id: String
    let thumbnail: String
    let title: String
    let description: String?
    let tag: String?
    let link: String?
    let type: Int?
}

// MARK: - New Release

struct NewReleaseData: Codable {
    let all: [NewReleaseSong]?
    let vPop: [NewReleaseSong]?
    let others: [NewReleaseSong]?
}

struct NewReleaseSong: Codable, Identifiable {
    let encodeId: String
    let title: String
    let thumbnail: String?
    let thumbnailM: String?
    let artistsNames: String?
    let releaseDate: Int?

    var id: String { encodeId }
}

// MARK: - Helper for safe array decoding

struct FailableDecodable<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
