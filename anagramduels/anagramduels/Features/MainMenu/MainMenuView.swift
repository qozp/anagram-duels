import SwiftUI

struct MainMenuView: View {

    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var authService: AuthService

    @StateObject private var viewModel: MainMenuViewModel = {
        // Injected properly in RootView via environment, but safe to init here.
        MainMenuViewModel(authService: AuthService())
    }()

    var body: some View {
        ZStack {
            Color.adBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 16)

                Spacer()

                menuButtons
                    .padding(.horizontal, 28)

                Spacer()

                footer
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Re-inject the real authService from environment
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            // Word mark
            HStack(spacing: 4) {
                ForEach(Array("DUEL".enumerated()), id: \.offset) { _, letter in
                    LetterTileView(letter: String(letter), size: 46)
                }
            }

            Text("Anagram Duels")
                .font(.title.bold())
                .foregroundStyle(Color.adTextPrimary)

            if let user = authService.currentUser {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Color.adPrimary)
                    Text(user.username)
                        .font(.subheadline)
                        .foregroundStyle(Color.adTextSecondary)
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Menu Buttons

    private var menuButtons: some View {
        VStack(spacing: 14) {
            MenuButtonView(
                title: "Challenge Friend",
                subtitle: "Invite a friend to a 1v1 duel",
                icon: "person.2.fill",
                style: .primary
            ) {
                router.navigate(to: .challengeFriend)
            }

            MenuButtonView(
                title: "Quick Match",
                subtitle: "Coming soon",
                icon: "bolt.fill",
                style: .secondary,
                disabled: true
            ) {}

            MenuButtonView(
                title: "Levels",
                subtitle: "Solo word challenges",
                icon: "list.number",
                style: .secondary
            ) {
                router.navigate(to: .levels)
            }

            HStack(spacing: 14) {
                MenuButtonView(
                    title: "Profile",
                    subtitle: nil,
                    icon: "chart.bar.fill",
                    style: .compact
                ) {
                    router.navigate(to: .profile)
                }

                MenuButtonView(
                    title: "Settings",
                    subtitle: nil,
                    icon: "gearshape.fill",
                    style: .compact
                ) {
                    router.navigate(to: .settings)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Button(role: .destructive) {
            Task { await viewModel.signOut() }
        } label: {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.footnote)
                .foregroundStyle(Color.adTextSecondary)
        }
    }
}

// MARK: - Letter Tile (decorative header)
private struct LetterTileView: View {
    let letter: String
    let size: CGFloat

    var body: some View {
        Text(letter)
            .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.adPrimary)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
            .shadow(color: Color.adPrimary.opacity(0.4), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Menu Button
private enum MenuButtonStyle {
    case primary, secondary, compact
}

private struct MenuButtonView: View {
    let title: String
    let subtitle: String?
    let icon: String
    let style: MenuButtonStyle
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(style == .compact ? .subheadline.bold() : .headline)
                        .foregroundStyle(titleColor)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.adTextSecondary)
                    }
                }

                Spacer()

                if !disabled {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.adTextSecondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, style == .compact ? 14 : 18)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private var background: some View {
        Group {
            if style == .primary {
                Color.adPrimary
            } else {
                Color.adSurface
            }
        }
    }

    private var titleColor: Color {
        style == .primary ? .white : Color.adTextPrimary
    }

    private var iconColor: Color {
        style == .primary ? .white : Color.adPrimary
    }

    private var borderColor: Color {
        style == .primary ? .clear : Color.adTextSecondary.opacity(0.15)
    }
}
