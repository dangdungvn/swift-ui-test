import Foundation

@Observable
class SearchViewModel {
    var query = ""
    var result: SearchResult?
    var isLoading = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    var songs: [SearchSong] { result?.songs ?? [] }
    var artists: [SearchArtist] { result?.artists ?? [] }
    var videos: [VideoItem] { result?.videos ?? [] }
    var playlists: [Playlist] { result?.playlists ?? [] }
    var hasResults: Bool { !songs.isEmpty || !artists.isEmpty || !videos.isEmpty || !playlists.isEmpty }

    func onQueryChanged() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            result = nil
            errorMessage = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    private func performSearch(_ keyword: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            result = try await APIClient.shared.fetch(.search(keyword: keyword))
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }
}
