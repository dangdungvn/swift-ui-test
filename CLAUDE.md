# CLAUDE.md

## Project Overview

App nghe nhac SwiftUI, phong cach Liquid Glass (iOS 26). Gom 3 man hinh chinh: Home feed, Top 100 charts, Playlist detail. Backend la REST API qua ngrok.

## Tech Stack

- **SwiftUI** only (khong UIKit), target **iOS 26.2**
- **Observation framework** (`@Observable`) — khong dung `ObservableObject`
- **Swift Concurrency** (async/await) cho networking
- **iOS 26 Liquid Glass APIs**: `.glassEffect()`, `GlassEffectContainer`, `.buttonStyle(.glass)`, `.scrollEdgeEffectStyle(.soft)`
- Khong co external dependencies (SPM/CocoaPods)

## Architecture

```
View (@State var viewModel) → ViewModel (@Observable) → APIClient.shared → Codable Models
```

- **MVVM** don gian, khong repository/use-case layer
- **APIClient** singleton xu ly toan bo networking (generic `fetch<T>()`)
- **Models** la Codable DTOs map truc tiep tu API response
- **NavigationStack** + typed `.navigationDestination(for: Playlist.self)`

## Project Structure

```
swift-ui-test/
├── swift_ui_testApp.swift      # @main, force dark mode
├── ContentView.swift           # TabView shell (4 tabs)
├── APIClient.swift             # APIError, APIEndpoint, APIResponseWrapper<T>, APIClient
├── SharedComponents.swift      # AppBackdrop, AppScreenHeader, AppStatusView, AppSectionHeader,
│                               # GlassBadge, GlassActionButton, MediaArtworkView, GlassPanel
├── HomeView.swift              # HomeView + HomeSectionRouter, QuickPlayCard, HomePlaylistCard,
│                               # NewReleaseSectionView, TabPill, NewReleaseSongRow
├── HomeViewModel.swift         # Paginated home feed
├── HomeModels.swift            # HomeData, HomeSection (custom decoding), Banner, QuickPlayItem,
│                               # NewReleaseData, NewReleaseSong, FailableDecodable<T>
├── Top100View.swift            # Top100View, FeaturedCard, GridCard
├── Top100ViewModel.swift       # Load top 100 sections
├── Top100Models.swift          # MusicSection, Playlist, Artist
├── PlaylistDetailView.swift    # PlaylistDetailView, PlaylistSongRow, ArtistChipView
├── PlaylistDetailViewModel.swift # Seed playlist + fetched detail fallback
└── PlaylistDetailModels.swift  # PlaylistDetail, PlaylistGenre, PlaylistSongCollection, PlaylistSong
```

## API

- **Base URL**: `https://real-apparently-wombat.ngrok-free.app`
- **Endpoints** (GET only, no auth):
  - `/api/home?page={n}` — home feed (paginated)
  - `/api/top100` — top 100 charts
  - `/api/detailplaylist?id={encodeId}` — playlist detail
- **Response format**: `{ "err": 0, "msg": "...", "data": T }`
- Tat ca di qua `APIClient.shared.fetch(.endpoint)` voi generic `APIResponseWrapper<T>`

## Key Patterns

- **GlassEffectContainer** boc nhom cac item co `.glassEffect()` de tao hieu ung lien ket
- **FailableDecodable<T>** trong HomeModels cho phep skip item decode loi ma khong crash ca array
- **PlaylistDetailViewModel** dung seed `Playlist` lam fallback khi chua fetch xong detail
- **HomeSection** co custom `init(from:)` decode polymorphic `items` theo `sectionType`
- Background dung `MeshGradient` + blurred `AsyncImage` overlay

## Build

```bash
xcodebuild -scheme swift-ui-test -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build
```

## Conventions
ung `MeshGradient` + blurred `AsyncImage` overlay

## Build

```bash
xcodebuild -scheme swift-ui-test -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build
```

## Conventions

- Tat ca ViewModel dung `@Observable`, view giu bang `@State`
- View trigger fetch voi `.task { await viewModel.fetch() }`
- Error hien thi qua `viewModel.errorMessage` (localized tu `APIError`)
- UI text hien tai dung tieng Viet khong dau
