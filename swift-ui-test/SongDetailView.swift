import SwiftUI

struct SongDetailView: View {
    private enum ContentMode: String {
        case artwork = "Phat"
        case lyrics = "Loi"
    }

    @State var audioPlayer = AudioPlayerManager.shared
    @Namespace private var heroNamespace
    @State private var contentMode: ContentMode = .artwork
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    private let lyricDelayMs = 260

    private var lyricLines: [LyricLine] {
        audioPlayer.currentLyric?.sentences?.map { LyricLine(sentence: $0) } ?? []
    }

    private var hasLyrics: Bool { !lyricLines.isEmpty }

    private var displayProgress: Double {
        isDragging ? dragProgress : audioPlayer.progress
    }

    private var displayTime: Double {
        isDragging ? dragProgress * audioPlayer.duration : audioPlayer.currentTime
    }

    private var lyricTimeMs: Int {
        max(0, Int(audioPlayer.currentTime * 1000) - lyricDelayMs)
    }

    private var canShowLyrics: Bool {
        hasLyrics || audioPlayer.currentSongInfo?.hasLyric == true
    }

    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 10) {
                topBarSection
                if canShowLyrics {
                    modeSwitcherSection
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControlsSection
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.22), .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .presentationBackground(.black)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            AppBackdrop()

            AsyncImage(url: URL(string: audioPlayer.currentSong?.thumbnail ?? "")) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 62)
                        .opacity(0.32)
                        .scaleEffect(1.4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, .black.opacity(0.5), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        ZStack {
            if contentMode == .lyrics {
                lyricsContent
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }

            if contentMode == .artwork {
                playerContent
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 70)
                .allowsHitTesting(false)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 90)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 6)
        .animation(.smooth(duration: 0.3), value: contentMode)
    }

    // MARK: - Top Bar

    private var topBarSection: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("DANG PHAT")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.9)
                    .foregroundStyle(.white.opacity(0.5))

                if let album = audioPlayer.currentSongInfo?.album {
                    Text(album.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }
            }

            HStack {
                Button {
                    audioPlayer.dismissSongDetail()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.backward")
                            .font(.footnote.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .capsule)
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                }
            }
        }
        .frame(height: 44)
    }

    private var modeSwitcherSection: some View {
        HStack(spacing: 8) {
            modePill(title: ContentMode.artwork.rawValue, mode: .artwork, icon: "music.note")
            modePill(title: ContentMode.lyrics.rawValue, mode: .lyrics, icon: "quote.bubble")
        }
        .padding(6)
        .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 24))
    }

    private func modePill(title: String, mode: ContentMode, icon: String) -> some View {
        Button {
            contentMode = mode
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(contentMode == mode ? .white : .white.opacity(0.55))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 38)
            .glassEffect(
                contentMode == mode
                    ? .regular.tint(Color(red: 0.34, green: 0.18, blue: 0.42).opacity(0.52)).interactive()
                    : .regular.tint(.white.opacity(0.06)).interactive(),
                in: .capsule
            )
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player Content (Artwork + Song Info)

    private var playerContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 14)

            GlassEffectContainer(spacing: 0) {
                MediaArtworkView(url: audioPlayer.currentSong?.thumbnail ?? "", cornerRadius: 28)
                    .matchedGeometryEffect(id: "song-artwork", in: heroNamespace)
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: UIScreen.main.bounds.width - 72)
                    .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
                    .shadow(color: .purple.opacity(0.15), radius: 30, y: 10)
                    .glassEffect(.regular.tint(.white.opacity(0.03)), in: .rect(cornerRadius: 28))
            }
            .padding(.horizontal, 36)

            Spacer(minLength: 20)

            songInfoSection
                .padding(.horizontal, 28)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 10)
    }

    private var songInfoSection: some View {
        VStack(spacing: 8) {
            Text(audioPlayer.currentSong?.title ?? "Khong co bai hat")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(audioPlayer.currentSong?.artistsNames ?? "")
                .font(.body)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)

            if let info = audioPlayer.currentSongInfo {
                songMetaChips(info)
            }
        }
    }

    @ViewBuilder
    private func songMetaChips(_ info: SongInfo) -> some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                if let genre = info.genres?.first?.name, !genre.isEmpty {
                    GlassBadge(genre)
                }
                if let composer = info.composers?.first?.name, !composer.isEmpty {
                    GlassBadge(composer, systemImage: "music.quarternote.3")
                }
                if let likes = info.like, likes > 0 {
                    GlassBadge(formatNumber(likes), systemImage: "heart.fill")
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Lyrics Content

    private var lyricsContent: some View {
        Group {
            if hasLyrics {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        MediaArtworkView(url: audioPlayer.currentSong?.thumbnail ?? "", cornerRadius: 12)
                            .matchedGeometryEffect(id: "song-artwork", in: heroNamespace)
                            .frame(width: 50, height: 50)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(audioPlayer.currentSong?.title ?? "")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .lineLimit(1)

                            Text(audioPlayer.currentSong?.artistsNames ?? "")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .glassEffect(.regular.tint(.white.opacity(0.08)).interactive(), in: .capsule)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    SyncedLyricsView(
                        lines: lyricLines,
                        currentTimeMs: lyricTimeMs,
                        isPlaying: audioPlayer.isPlaying,
                        onTapLine: { line in
                            audioPlayer.seek(to: Double(line.startTime) / 1000.0)
                        }
                    )
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
                .padding(.top, 8)
                .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 28))
                .padding(.horizontal, 12)
            } else {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "text.quote")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.25))
                        .frame(width: 64, height: 64)
                        .glassEffect(.regular.tint(.white.opacity(0.06)), in: .circle)

                    Text("Khong co loi bai hat")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
                .glassEffect(.regular.tint(.white.opacity(0.04)).interactive(), in: .rect(cornerRadius: 28))
                .padding(.horizontal, 12)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Bottom Controls (always visible)

    private var bottomControlsSection: some View {
        VStack(spacing: 16) {
            // Progress
            progressSection
                .padding(.horizontal, 24)

            // Playback Controls
            controlsRow

            // Bottom actions
            bottomActionsRow
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
        }
            .padding(.top, 4)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 6) {
            SongProgressSlider(
                progress: displayProgress,
                isDragging: $isDragging,
                dragProgress: $dragProgress,
                onSeek: { fraction in
                    audioPlayer.seek(to: fraction * audioPlayer.duration)
                }
            )

            HStack {
                Text(formatTime(displayTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))

                Spacer()

                Text("-" + formatTime(max(0, audioPlayer.duration - displayTime)))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    // MARK: - Playback Controls

    private var controlsRow: some View {
        HStack(spacing: 0) {
            Button {} label: {
                Image(systemName: "shuffle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }

            Button {} label: {
                Image(systemName: "backward.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }

            Button {
                audioPlayer.togglePlayPause()
            } label: {
                ZStack {
                    if audioPlayer.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.1)
                    } else {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .frame(width: 68, height: 68)
                .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
            }

            Button {} label: {
                Image(systemName: "forward.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }

            Button {} label: {
                Image(systemName: "repeat")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Bottom Actions Row

    private var bottomActionsRow: some View {
        HStack {
            Button {} label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 36, height: 36)
            }

            Spacer()

            if hasLyrics || audioPlayer.currentSongInfo?.hasLyric == true {
                Button {
                    contentMode = contentMode == .lyrics ? .artwork : .lyrics
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "quote.bubble")
                            .font(.caption.weight(.semibold))
                        Text("Loi bai hat")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(contentMode == .lyrics ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .glassEffect(
                        contentMode == .lyrics
                            ? .regular.tint(Color(red: 0.34, green: 0.18, blue: 0.42).opacity(0.5)).interactive()
                            : .regular.tint(.white.opacity(0.06)).interactive(),
                        in: .capsule
                    )
                }
            }

            Spacer()

            Button {} label: {
                Image(systemName: "airplayaudio")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func formatNumber(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Progress Slider

struct SongProgressSlider: View {
    let progress: Double
    @Binding var isDragging: Bool
    @Binding var dragProgress: Double
    let onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fillWidth = max(0, min(width * progress, width))
            let thumbSize: CGFloat = isDragging ? 14 : 6

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .frame(height: 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.34, green: 0.18, blue: 0.42).opacity(0.9),
                                .white.opacity(0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth, height: 4)

                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .white.opacity(0.25), radius: 3)
                    .position(x: fillWidth, y: geo.size.height / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        dragProgress = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { value in
                        let fraction = min(max(value.location.x / width, 0), 1)
                        onSeek(fraction)
                        isDragging = false
                    }
            )
            .animation(.easeOut(duration: 0.12), value: isDragging)
        }
        .frame(height: 28)
    }
}

// MARK: - Synced Lyrics View

struct SyncedLyricsView: View {
    let lines: [LyricLine]
    let currentTimeMs: Int
    let isPlaying: Bool
    let onTapLine: (LyricLine) -> Void

    private var activeIndex: Int? {
        lines.lastIndex { $0.startTime <= currentTimeMs && currentTimeMs < $0.endTime }
            ?? lines.lastIndex { $0.startTime <= currentTimeMs }
    }

    private func progress(for line: LyricLine) -> Double {
        guard line.endTime > line.startTime else { return currentTimeMs >= line.endTime ? 1 : 0 }
        let raw = Double(currentTimeMs - line.startTime) / Double(line.endTime - line.startTime)
        return min(max(raw, 0), 1)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        Spacer().frame(height: 34)

                        ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                            let isActive = index == activeIndex
                            let isPast: Bool = {
                                guard let active = activeIndex else { return false }
                                return index < active
                            }()

                            LyricLineRow(
                                line: line,
                                isActive: isActive,
                                isPast: isPast,
                                progress: progress(for: line),
                                onTap: { onTapLine(line) }
                            )
                            .id(line.id)
                        }

                        Spacer().frame(height: 120)
                    }
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectStyle(.soft, for: .bottom)

                VStack {
                    Spacer()

                    LinearGradient(
                        colors: [.black.opacity(0.0), .black.opacity(0.14), .black.opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 6)
            .onAppear {
                guard let idx = activeIndex, idx < lines.count else { return }
                proxy.scrollTo(lines[idx].id, anchor: .center)
            }
            .onChange(of: activeIndex) { _, newIndex in
                guard let idx = newIndex, idx < lines.count else { return }
                guard isPlaying else { return }
                withAnimation(.linear(duration: 0.2)) {
                    proxy.scrollTo(lines[idx].id, anchor: .center)
                }
            }
        }
    }
}

private struct LyricLineRow: View {
    let line: LyricLine
    let isActive: Bool
    let isPast: Bool
    let progress: Double
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text(line.text)
                    .font(isActive ? .title2.weight(.bold) : .title3.weight(.semibold))
                    .foregroundStyle(baseColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)

                if isActive {
                    GeometryReader { geo in
                        Text(line.text)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        .white,
                                        Color(red: 0.88, green: 0.78, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)
                            .mask(alignment: .leading) {
                                Rectangle()
                                    .frame(width: max(2, geo.size.width * progress))
                            }
                    }
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, isActive ? 18 : 14)
            .background {
                if isActive {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.08))
                        .padding(.horizontal, 16)
                        .shadow(color: .white.opacity(0.1), radius: 8)
                }
            }
            .scaleEffect(isActive ? 1.01 : 1)
            .animation(.easeOut(duration: 0.2), value: isActive)
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private var baseColor: Color {
        if isActive { return .white.opacity(0.35) }
        if isPast { return .white.opacity(0.20) }
        return .white.opacity(0.42)
    }
}
