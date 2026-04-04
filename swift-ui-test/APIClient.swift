import Foundation

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case apiError(code: Int, message: String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL khong hop le"
        case .httpError(let statusCode):
            return "Loi server (HTTP \(statusCode))"
        case .apiError(_, let message):
            return message
        case .decodingError:
            return "Khong the xu ly du lieu tra ve"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - API Response Wrapper

struct APIResponseWrapper<T: Decodable>: Decodable {
    let err: Int
    let msg: String
    let data: T
}

// MARK: - API Endpoint

enum APIEndpoint {
    case home(page: Int)
    case top100
    case playlistDetail(id: String)

    var path: String {
        switch self {
        case .home: return "/api/home"
        case .top100: return "/api/top100"
        case .playlistDetail: return "/api/detailplaylist"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .home(let page):
            return [URLQueryItem(name: "page", value: String(page))]
        case .top100:
            return []
        case .playlistDetail(let id):
            return [URLQueryItem(name: "id", value: id)]
        }
    }
}

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://real-apparently-wombat.ngrok-free.app"
    private let session = URLSession.shared
    private let decoder = JSONDecoder()

    private init() {}

    func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws(APIError) -> T {
        guard var components = URLComponents(string: baseURL) else {
            throw .invalidURL
        }
        components.path = endpoint.path
        let queryItems = endpoint.queryItems
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw .invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .networkError(error)
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw .httpError(statusCode: httpResponse.statusCode)
        }

        let wrapper: APIResponseWrapper<T>
        do {
            wrapper = try decoder.decode(APIResponseWrapper<T>.self, from: data)
        } catch {
            throw .decodingError(error)
        }

        guard wrapper.err == 0 else {
            throw .apiError(code: wrapper.err, message: wrapper.msg)
        }

        return wrapper.data
    }
}
