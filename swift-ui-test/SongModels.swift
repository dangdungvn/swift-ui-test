import Foundation

// MARK: - Song Streaming Data

struct SongStreamingData: Codable {
    let url128: String?
    let url320: String?

    enum CodingKeys: String, CodingKey {
        case url128 = "128"
        case url320 = "320"
    }

    var bestURL: String? {
        [url320, url128].first(where: { candidate in
            guard let candidate,
                  let url = URL(string: candidate),
                  let scheme = url.scheme?.lowercased() else {
                return false
            }
            return scheme == "http" || scheme == "https"
        }) ?? nil
    }
}

// MARK: - Song Info

struct SongInfo: Decodable {
    let encodeId: String
    let title: String
    let alias: String?
    let artistsNames: String?
    let artists: [Artist]?
    let thumbnail: String?
    let thumbnailM: String?
    let duration: Int?
    let album: Playlist?
    let hasLyric: Bool?
    let mvlink: String?
    let releaseDate: Int?
    let distributor: String?
    let genres: [SongGenre]?
    let composers: [SongContributor]?
    let like: Int?
    let comment: Int?
    let streamingStatus: Int?
}

// MARK: - Lyric

struct SongLyric: Decodable {
    let enabledVideoBG: Bool?
    let sentences: [LyricSentence]?
    let file: String?
    let defaultIBGUrls: [String]?
    let BGMode: Int?
}

struct LyricSentence: Decodable, Identifiable {
    let words: [LyricWord]

    var id: String {
        words.first?.id ?? UUID().uuidString
    }
}

struct LyricWord: Decodable, Identifiable {
    let startTime: Int
    let endTime: Int
    let data: String

    var id: String {
        "\(startTime)-\(endTime)-\(data)"
    }
}

// MARK: - Supporting Types

struct SongGenre: Decodable, Identifiable {
    let id: String
    let name: String
    let title: String?
    let alias: String?
    let link: String?
}

struct SongContributor: Decodable, Identifiable {
    let id: String
    let name: String
    let alias: String?
    let thumbnail: String?
    let playlistId: String?
    let totalFollow: Int?
}

struct LyricLine: Identifiable, Equatable {
    let id: String
    let text: String
    let startTime: Int
    let endTime: Int

    init(sentence: LyricSentence) {
        let words = sentence.words
        self.text = words
            .map { $0.data.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.startTime = words.map(\.startTime).min() ?? 0
        self.endTime = words.map(\.endTime).max() ?? 0
        self.id = "\(startTime)-\(endTime)-\(text)"
    }
}
