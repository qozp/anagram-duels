import SwiftUI

struct GameBoardView: View {

    @StateObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    // Layout
    private let tileSizeRatio: CGFloat = 0.13   // fraction of screen width per tile
    private let slotSpacing: CGFloat = 6
    private let handSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let tileSize = geo.size.width * tileSizeRatio

            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                switch viewModel.phase {
                case .countdown(let seconds):
                    CountdownView(seconds: seconds)

                case .playing:
                    playingLayout(tileSize: tileSize, geo: geo)

                case .results:
                    ResultsView(viewModel: viewModel, onDismiss: { dismiss() })
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.startGame() }
    }

    // MARK: - Playing Layout

    @ViewBuilder
    private func playingLayout(tileSize: CGFloat, geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {

            // Timer bar
            timerBar(width: geo.size.width)
                .padding(.top, 8)

            Spacer()

            // Feedback toast
            if let message = viewModel.feedbackMessage {
                FeedbackToast(message: message)
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Word slots row
            wordSlotsRow(tileSize: tileSize)
                .padding(.horizontal, 16)

            Spacer(minLength: 24)

            // Submitted words tally (score only during play)
            scoreBadge()

            Spacer(minLength: 16)

            // Action buttons
            actionButtons(tileSize: tileSize)
                .padding(.horizontal, 24)

            Spacer(minLength: 20)

            // Hand tiles row
            handRow(tileSize: tileSize)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.feedbackMessage)
    }

    // MARK: - Timer Bar

    private func timerBar(width: CGFloat) -> some View {
        let fraction = Double(viewModel.timeRemaining) / Double(AppConfig.gameDuration)
        return VStack(spacing: 4) {
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                Text("\(viewModel.timeRemaining)s")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(Color.timerColor(fractionElapsed: 1.0 - fraction))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemFill))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.timerColor(fractionElapsed: 1.0 - fraction))
                    .frame(width: max(0, width * fraction - 32), height: 6)
                    .animation(.linear(duration: 1), value: viewModel.timeRemaining)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Word Slots

    private func wordSlotsRow(tileSize: CGFloat) -> some View {
        HStack(spacing: slotSpacing) {
            ForEach(0..<AppConfig.seedWordLength, id: \.self) { slotIndex in
                let tileID = viewModel.wordSlots[slotIndex]
                let tile = tileID.flatMap { id in viewModel.handTiles.first(where: { $0.id == id }) }
                WordSlotView(tile: tile, tileSize: tileSize) {
                    viewModel.tapWordSlot(at: slotIndex)
                }
            }
        }
    }

    // MARK: - Hand Row

    private func handRow(tileSize: CGFloat) -> some View {
        HStack(spacing: handSpacing) {
            ForEach(viewModel.handTiles) { tile in
                LetterTileView(
                    letter: tile.letter,
                    state: tile.isPlaced ? .placed : .available,
                    size: tileSize
                ) {
                    viewModel.tapHandTile(id: tile.id)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(tileSize: CGFloat) -> some View {
        HStack(spacing: 12) {
            // Clear All
            Button(action: viewModel.clearWord) {
                Label("Clear", systemImage: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            .disabled(viewModel.currentWordIsEmpty)

            // Submit
            Button(action: viewModel.submitCurrentWord) {
                HStack {
                    Text("Submit")
                        .font(.system(size: 16, weight: .bold))
                    if !viewModel.currentWordIsEmpty {
                        Text("(\(viewModel.currentWordString.count))")
                            .font(.system(size: 13, weight: .regular))
                            .opacity(0.7)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(viewModel.currentWordIsEmpty ? Color.accentColor.opacity(0.4) : Color.accentColor)
                .cornerRadius(10)
            }
            .disabled(viewModel.currentWordIsEmpty)
        }
    }

    // MARK: - Score Badge

    private func scoreBadge() -> some View {
        HStack(spacing: 16) {
            Label("\(viewModel.submittedWords.count) words", systemImage: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.green)

            Text("\(viewModel.totalScore) pts")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

// MARK: - Countdown View
struct CountdownView: View {
    let seconds: Int

    var body: some View {
        VStack(spacing: 16) {
            Text("Get Ready!")
                .font(.title2.bold())
                .foregroundColor(.secondary)
            Text("\(seconds)")
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundColor(.accentColor)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: seconds)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
