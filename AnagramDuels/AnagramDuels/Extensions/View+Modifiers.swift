import SwiftUI

// MARK: - Card Style
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Shake Animation (for invalid word)
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakes: Int = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakes)),
            y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ConditionalShake(trigger: trigger))
    }
}

struct ConditionalShake: ViewModifier {
    var trigger: Bool
    @State private var attempts: Int = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: CGFloat(attempts)))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.default) { attempts += 1 }
                }
            }
    }
}

// MARK: - Primary Button
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDestructive ? Color.red : Color.accent)
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var destructive: PrimaryButtonStyle { PrimaryButtonStyle(isDestructive: true) }
}

// MARK: - Feedback Toast
struct FeedbackToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .cornerRadius(20)
    }
}
