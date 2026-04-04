import Foundation

@Observable
class HomeViewModel {
    var sections: [HomeSection] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var currentPage = 1
    var hasMore = true

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
        let homeData: HomeData = try await APIClient.shared.fetch(.home(page: page))

        if let more = homeData.hasMore {
            hasMore = more
        }

        return homeData.items.filter { $0.isDisplayable }
    }

    var displayableSections: [HomeSection] {
        sections
    }
}
