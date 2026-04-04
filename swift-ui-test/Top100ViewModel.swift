import Foundation

@Observable
class Top100ViewModel {
    var sections: [MusicSection] = []
    var isLoading = false
    var errorMessage: String?

    func fetchTop100() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            sections = try await APIClient.shared.fetch(.top100)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var featuredSection: MusicSection? {
        sections.first { $0.viewType == "slider" }
    }

    var listSections: [MusicSection] {
        sections.filter { $0.viewType == "list" }
    }
}
