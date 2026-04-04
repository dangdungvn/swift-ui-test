import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Kham pha", systemImage: "music.note.house.fill", value: 0) {
                HomeView()
            }
            Tab("Top 100", systemImage: "chart.bar.fill", value: 1) {
                Top100View()
            }
            Tab("Tim kiem", systemImage: "magnifyingglass", value: 2) {
                SearchPlaceholderView()
            }
            Tab("Thu vien", systemImage: "square.stack.fill", value: 3) {
                LibraryPlaceholderView()
            }
        }
        .tint(.white)
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }
}

// MARK: - Placeholder Tabs

struct SearchPlaceholderView: View {
    var body: some View {
        ZStack {
            AppBackdrop()
            AppStatusView(
                systemImage: "magnifyingglass",
                title: "Tim kiem",
                message: "Khu vuc nay co the dung lai de tao search experience sau.",
                style: .placeholder
            )
        }
    }
}

struct LibraryPlaceholderView: View {
    var body: some View {
        ZStack {
            AppBackdrop(colors: AppBackdrop.top100Colors)
            AppStatusView(
                systemImage: "square.stack.fill",
                title: "Thu vien",
                message: "Noi tap trung playlist da luu, history va nhac cua ban.",
                style: .placeholder
            )
        }
    }
}

// MARK: - Make Playlist Hashable for NavigationLink

extension Playlist: Hashable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.encodeId == rhs.encodeId
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(encodeId)
    }
}

#Preview {
    ContentView()
}
