import SwiftUI

// MARK: - Logo Tiles View
// Displays the animated "DUEL" letter tiles with per-letter color states.
// Used on WelcomeView and as the persistent top header in MainTabView.

struct LogoTilesView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    // Configuration
    var word: String         = "DUELS"
    var tileSize: CGFloat    = 42
    var fontSize: CGFloat?   = nil   // nil = auto-scaled from tileSize
    var spacing: CGFloat     = 4
    var animated: Bool       = true  // false = appear instantly (for persistent header)

    // One state per letter in `word`. Cycles through defaults if fewer are provided.
    var states: [WordTileState] = [.normal, .selected, .correct, .wrong, .normal]

    private enum Layout {
        static let cornerRadius: CGFloat = 8
        static let staggerDelay: Double  = 0.08
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(word.enumerated()), id: \.offset) { index, letter in
                LogoTileCell(
                    letter:       String(letter),
                    index:        index,
                    state:        states[index % states.count],
                    size:         tileSize,
                    fontSize:     fontSize ?? tileSize * 0.48,
                    cornerRadius: Layout.cornerRadius,
                    staggerDelay: Layout.staggerDelay,
                    animated:     animated
                )
            }
        }
    }
}

// MARK: - Single Tile Cell

private struct LogoTileCell: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let letter:       String
    let index:        Int
    let state:        WordTileState
    let size:         CGFloat
    let fontSize:     CGFloat
    let cornerRadius: CGFloat
    let staggerDelay: Double
    let animated:     Bool

    @State private var appeared: Bool = false

    var body: some View {
        Text(letter)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(textColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .shadow(color: theme.shadow, radius: 3, x: 0, y: 2)
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                if animated {
                    withAnimation(
                        .spring(response: 0.45, dampingFraction: 0.65)
                        .delay(Double(index) * staggerDelay)
                    ) {
                        appeared = true
                    }
                } else {
                    appeared = true
                }
            }
    }

    // MARK: Derived Colors (mirrors WordTileView logic)

    private var backgroundColor: Color {
        switch state {
        case .normal:   return theme.tileBackground
        case .selected: return theme.tileBackgroundSelected
        case .used:     return theme.tileBackgroundUsed
        case .correct:  return theme.tileBackgroundCorrect
        case .wrong:    return theme.tileBackgroundWrong
        }
    }

    private var textColor: Color {
        switch state {
        case .normal: return theme.tileText
        case .used:   return theme.tileText.opacity(0.4)
        default:      return theme.tileTextSelected
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:   return theme.tileBorder
        case .selected: return theme.tileBackgroundSelected
        case .used:     return theme.tileBorder.opacity(0.4)
        case .correct:  return theme.tileBackgroundCorrect
        case .wrong:    return theme.tileBackgroundWrong
        }
    }
}
