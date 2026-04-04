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

        guard let url = URL(string: "https://real-apparently-wombat.ngrok-free.app/api/top100") else {
            errorMessage = "Invalid URL"
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(APIResponse.self, from: data)
            if response.err == 0 {
                sections = response.data
            } else {
                errorMessage = response.msg
            }
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
