import SwiftUI

/// Animated letter tiles that spell "DUEL" — used as the app logo on the welcome screen.
struct LogoTilesView: View {

    var tileSize: CGFloat = 56
    var spacing: CGFloat  = 8
    var animated: Bool    = true

    private let letters: [Character] = ["D", "U", "E", "L"]

    // Each tile drops in sequentially
    @State private var appeared: [Bool] = [false, false, false, false]

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                LogoTile(letter: letter, size: tileSize)
                    .offset(y: appeared[index] ? 0 : -20)
                    .opacity(appeared[index] ? 1 : 0)
                    .scaleEffect(appeared[index] ? 1 : 0.7)
            }
        }
        .onAppear {
            guard animated else {
                appeared = [true, true, true, true]
                return
            }
            for i in letters.indices {
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.6)
                    .delay(Double(i) * 0.1)
                ) {
                    appeared[i] = true
                }
            }
        }
    }
}

// MARK: - Individual Logo Tile
private struct LogoTile: View {
    let letter: Character
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(Color.accentColor)
                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)

            Text(String(letter))
                .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
