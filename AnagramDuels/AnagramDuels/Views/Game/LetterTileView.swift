import SwiftUI

// MARK: - Letter Tile View
struct LetterTileView: View {

    let letter: Character
    let state: LetterTileState
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: tileCornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: tileCornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(
                        color: state == .available ? .black.opacity(0.18) : .clear,
                        radius: 3, x: 0, y: 2
                    )

                Text(String(letter).uppercased())
                    .font(.system(size: letterFontSize(for: size), weight: .bold, design: .rounded))
                    .foregroundColor(letterColor)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .scaleEffect(state == .available ? 1.0 : 0.95)
        .opacity(state == .hidden ? 0 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: state)
        .disabled(state == .disabled || state == .hidden)
    }

    // MARK: - Computed Style

    private var tileCornerRadius: CGFloat { size * 0.18 }
    private var borderWidth: CGFloat { state == .inSlot ? 0 : 1.5 }

    private var backgroundColor: Color {
        switch state {
        case .available: return Color(.systemBackground).opacity(0.95)
        case .inSlot:    return Color.accentColor.opacity(0.15)
        case .placed:    return Color(.secondarySystemBackground)
        case .disabled:  return Color(.tertiarySystemBackground)
        case .hidden:    return .clear
        }
    }

    private var borderColor: Color {
        switch state {
        case .available: return Color(.separator)
        case .inSlot:    return Color.accentColor
        case .placed:    return Color(.separator).opacity(0.5)
        default:         return .clear
        }
    }

    private var letterColor: Color {
        switch state {
        case .available: return Color(.label)
        case .inSlot:    return Color.accentColor
        case .placed:    return Color(.secondaryLabel)
        case .disabled:  return Color(.tertiaryLabel)
        case .hidden:    return .clear
        }
    }

    private func letterFontSize(for size: CGFloat) -> CGFloat {
        size * 0.52
    }
}

// MARK: - Word Slot View
struct WordSlotView: View {

    let tile: LetterTile?          // nil = empty slot
    let tileSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Slot background
                RoundedRectangle(cornerRadius: tileSize * 0.18)
                    .fill(slotFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: tileSize * 0.18)
                            .stroke(slotStrokeColor, lineWidth: 1.5)
                            .padding(1)
                    )
                    .frame(width: tileSize, height: tileSize)

                if let tile {
                    LetterTileView(
                        letter: tile.letter,
                        state: .inSlot,
                        size: tileSize,
                        onTap: onTap
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: tile?.id)
    }

    private var slotFillColor: Color {
        tile != nil
            ? Color(.systemBackground).opacity(0.0)   // hidden under tile
            : Color(.secondarySystemBackground).opacity(0.6)
    }

    private var slotStrokeColor: Color {
        tile != nil ? Color.clear : Color(.separator).opacity(0.7)
    }
}

// MARK: - Tile State
enum LetterTileState: Equatable {
    case available   // in hand, can be tapped
    case inSlot      // currently occupying a word slot
    case placed      // placed but greyed (same tile shown dimmed in hand)
    case disabled    // not interactive
    case hidden      // fully invisible (slot placeholder)
}
