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
    private let lyricDelayMs = 140

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
                    .frame(maxWidth: .infinity)
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
                VStack(spacing: 6) {
                    HStack(spacing: 7) {
                        MediaArtworkView(url: audioPlayer.currentSong?.thumbnail ?? "", cornerRadius: 9)
                            .matchedGeometryEffect(id: "song-artwork", in: heroNamespace)
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(audioPlayer.currentSong?.title ?? "")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .lineLimit(1)

                            Text(audioPlayer.currentSong?.artistsNames ?? "")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.58))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .glassEffect(.regular.tint(.white.opacity(0.08)).interactive(), in: .capsule)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)

                    SyncedLyricsView(
                        lines: lyricLines,
                        currentTimeMs: lyricTimeMs,
                        isPlaying: audioPlayer.isPlaying,
                        onTapLine: { line in
                            audioPlayer.seek(to: Double(line.startTime) / 1000.0)
                        }
                    )
                    .padding(.horizontal, 10)
                    .padding(.bottom, 2)
                }
                .padding(.top, 4)
                .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: 22))
                .padding(.horizontal, 14)
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
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                .frame(width: 68, height: 68)
                .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
            }
            .buttonStyle(.plain)

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
        lines.lastIndex { line in
            if line.words.contains(where: { currentTimeMs >= $0.startTime && currentTimeMs < $0.endTime }) {
                return true
            }
            guard let lastWord = line.words.last else { return false }
            return currentTimeMs >= lastWord.startTime
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        Spacer().frame(height: 14)

                        ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                            let isActive = index == activeIndex

                            LyricLineRow(
                                line: line,
                                isActive: isActive,
                                currentTimeMs: currentTimeMs,
                                onTap: { onTapLine(line) }
                            )
                            .id(line.id)
                        }

                        Spacer().frame(height: 64)
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
            .padding(.horizontal, 12)
            .onAppear {
                guard let idx = activeIndex, idx < lines.count else { return }
                proxy.scrollTo(lines[idx].id, anchor: .center)
            }
            .onChange(of: activeIndex) { _, newIndex in
                guard let idx = newIndex, idx < lines.count else { return }
                guard isPlaying else { return }
                withAnimation(.smooth(duration: 0.12)) {
                    proxy.scrollTo(lines[idx].id, anchor: .center)
                }
            }
        }
    }
}

private struct LyricLineRow: View {
    let line: LyricLine
    let isActive: Bool
    let currentTimeMs: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if line.words.isEmpty {
                    Text(line.text)
                        .font(isActive ? .callout.weight(.semibold) : .footnote.weight(.medium))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, isActive ? 7 : 5)
                } else {
                    WrappingHStack(horizontalSpacing: 3, verticalSpacing: 4) {
                        ForEach(Array(line.words.enumerated()), id: \.element.id) { _, word in
                            let isCurrentWord = currentTimeMs >= word.startTime && currentTimeMs < word.endTime
                            let isPastWord = currentTimeMs >= word.endTime

                            LyricWordToken(
                                word: word,
                                isCurrent: isCurrentWord,
                                isPast: isPastWord,
                                isActiveLine: isActive
                            )
                        }
                    }
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, isActive ? 6 : 4)
                }
            }
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .padding(.horizontal, 6)
                }
            }
            .animation(.smooth(duration: 0.14), value: isActive)
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

private struct LyricWordToken: View {
    let word: LyricWord
    let isCurrent: Bool
    let isPast: Bool
    let isActiveLine: Bool

    var body: some View {
        Text(word.data)
            .font(isCurrent ? .footnote.weight(.semibold) : .caption.weight(.medium))
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, isCurrent ? 4 : 2)
            .padding(.vertical, isCurrent ? 2 : 1)
            .background {
                if isCurrent {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.11))
                }
            }
            .scaleEffect(isCurrent ? 1.03 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.88), value: isCurrent)
    }

    private var foregroundStyle: Color {
        if isCurrent { return .white }
        if isPast { return isActiveLine ? .white.opacity(0.72) : .white.opacity(0.48) }
        return .white.opacity(0.38)
    }
}

private struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
