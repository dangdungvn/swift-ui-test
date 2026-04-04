import Foundation

@Observable
class HomeViewModel {
    var sections: [HomeSection] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var currentPage = 1
    var hasMore = true

    private let baseURL = "https://real-apparently-wombat.ngrok-free.app/api/home?page="

    func fetchHome() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMore = true
        defer { isLoading = false }

        do {
            let newSections = try await loadPage(1)
            sections = newSections
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreIfNeeded() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let newSections = try await loadPage(nextPage)
            if newSections.isEmpty {
                hasMore = false
            } else {
                sections.append(contentsOf: newSections)
                currentPage = nextPage
            }
        } catch {
            // Silently fail for pagination
        }
    }

    private func loadPage(_ page: Int) async throws -> [HomeSection] {
        guard let url = URL(string: "\(baseURL)\(page)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(HomeAPIResponse.self, from: data)

        if response.err != 0 {
            throw NSError(domain: "", code: response.err, userInfo: [NSLocalizedDescriptionKey: response.msg])
        }

        if let more = response.data.hasMore {
            hasMore = more
        }

        return response.data.items.filter { $0.isDisplayable }
    }

    var displayableSections: [HomeSection] {
        sections
    }
}
