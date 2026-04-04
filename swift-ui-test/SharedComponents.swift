import SwiftUI

struct AppBackdrop: View {
    let colors: [Color]

    init(colors: [Color] = AppBackdrop.defaultColors) {
        self.colors = colors
    }

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: colors
            )

            LinearGradient(
                colors: [
                    .black.opacity(0.08),
                    .black.opacity(0.42),
                    .black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    static let defaultColors: [Color] = [
        Color(red: 0.03, green: 0.05, blue: 0.12),
        Color(red: 0.14, green: 0.27, blue: 0.33),
        Color(red: 0.07, green: 0.08, blue: 0.18),
        Color(red: 0.08, green: 0.11, blue: 0.22),
        Color(red: 0.30, green: 0.16, blue: 0.34),
        Color(red: 0.11, green: 0.17, blue: 0.30),
        Color(red: 0.02, green: 0.03, blue: 0.08),
        Color(red: 0.11, green: 0.07, blue: 0.22),
        .black
    ]

    static let top100Colors: [Color] = [
        .black,
        Color(red: 0.11, green: 0.07, blue: 0.22),
        Color(red: 0.03, green: 0.11, blue: 0.20),
        Color(red: 0.15, green: 0.06, blue: 0.17),
        Color(red: 0.36, green: 0.11, blue: 0.25),
        Color(red: 0.11, green: 0.06, blue: 0.21),
        .black,
        Color(red: 0.10, green: 0.10, blue: 0.26),
        Color(red: 0.02, green: 0.05, blue: 0.12)
    ]
}

struct AppScreenHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String

    var body: some View {
        GlassPanel(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 10) {
                if let eyebrow, !eyebrow.isEmpty {
                    Text(eyebrow.uppercased())
                        .font(.caption.weight(.semibold))
                        .kerning(1.2)
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.tint(.white.opacity(0.08)).interactive(), in: .capsule)
                }

                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.74))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct AppStatusView: View {
    enum Style {
        case loading
        case error(actionTitle: String, action: () -> Void)
        case placeholder
    }

    let systemImage: String
    let title: String
    let message: String
    let style: Style

    var body: some View {
        GlassPanel(cornerRadius: 30) {
            VStack(spacing: 18) {
                if case .loading = style {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                        .padding(.bottom, 2)
                        .frame(width: 72, height: 72)
                        .glassEffect(.regular.tint(.white.opacity(0.06)), in: .circle)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 72, height: 72)
                        .glassEffect(.regular.tint(.white.opacity(0.08)), in: .circle)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                }

                if case .error(let actionTitle, let action) = style {
                    Button(actionTitle, action: action)
                        .buttonStyle(.glassProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

struct AppSectionHeader: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Spacer()
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular.tint(.white.opacity(0.06)).interactive(), in: .capsule)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct GlassBadge: View {
    let label: String
    let systemImage: String?
    let tint: Color

    init(_ label: String, systemImage: String? = nil, tint: Color = Color.white.opacity(0.12)) {
        self.label = label
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(tint).interactive(), in: .capsule)
    }
}

struct GlassActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.body)
            Text(title)
                .font(.body.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 14)
        .glassEffect(glassStyle, in: .capsule)
    }

    private var glassStyle: Glass {
        if let tint {
            return .regular.tint(tint).interactive()
        }
        return .regular.interactive()
    }
}

struct MediaArtworkView: View {
    let url: String
    let cornerRadius: CGFloat
    let icon: String

    init(url: String, cornerRadius: CGFloat = 18, icon: String = "music.note") {
        self.url = url
        self.cornerRadius = cornerRadius
        self.icon = icon
    }

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                fallbackView
            default:
                placeholderView
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white.opacity(0.08))
            .overlay {
                ProgressView()
                    .tint(.white.opacity(0.45))
            }
            .glassEffect(.regular.tint(.white.opacity(0.05)), in: .rect(cornerRadius: cornerRadius))
    }

    private var fallbackView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white.opacity(0.08))
            .overlay {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.35))
            }
            .glassEffect(.regular.tint(.white.opacity(0.05)), in: .rect(cornerRadius: cornerRadius))
    }
}

struct GlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .glassEffect(.regular.tint(.white.opacity(0.05)).interactive(), in: .rect(cornerRadius: cornerRadius))
    }
}
