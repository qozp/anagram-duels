import SwiftUI

// MARK: - Tile State

enum WordTileState {
    case normal
    case selected
    case used
    case correct
    case wrong
}

// MARK: - Word Tile View

struct WordTileView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    private var theme: AppTheme { themeManager.current }

    let letter: String
    var state: WordTileState     = .normal
    var size: CGFloat            = 48
    var cornerRadius: CGFloat    = 10
    var fontSize: CGFloat?       = nil    // nil = auto-scaled from size

    var body: some View {
        Text(letter.uppercased())
            .font(.system(size: fontSize ?? size * 0.48, weight: .bold, design: .rounded))
            .foregroundColor(textColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .shadow(color: theme.shadow, radius: 3, x: 0, y: 2)
            .scaleEffect(state == .selected ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: state)
    }

    // MARK: Derived Colors

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
        case .normal:  return theme.tileText
        case .used:    return theme.tileText.opacity(0.4)
        default:       return theme.tileTextSelected
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

// MARK: - Preview Helper

#Preview {
    let letters: [String]         = ["N","O","R","M","A","L"]
    let states: [WordTileState]   = [.normal, .selected, .correct, .wrong, .used, .normal]

    HStack(spacing: 8) {
        ForEach(letters.indices, id: \.self) { index in
            WordTileView(letter: letters[index], state: states[index])
        }
    }
    .padding()
    .environmentObject(ThemeManager())
}
