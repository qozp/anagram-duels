import SwiftUI

struct ResultsView: View {

    @ObservedObject var viewModel: GameViewModel
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Header
                VStack(spacing: 6) {
                    Text("Time's Up!")
                        .font(.largeTitle.bold())
                    Text("\(viewModel.totalScore) points")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 32)

                // Words list
                if viewModel.submittedWords.isEmpty {
                    ContentUnavailableView("No words found", systemImage: "text.magnifyingglass")
                        .padding()
                } else {
                    wordsGrid
                }

                // Save status
                if viewModel.isSubmittingResult {
                    HStack {
                        ProgressView()
                        Text("Saving...")
                            .foregroundColor(.secondary)
                    }
                }

                if let error = viewModel.resultSaveError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button("Done", action: onDismiss)
                    .buttonStyle(.primary)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Words Grid

    private var wordsGrid: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Words Found")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)

            ForEach(viewModel.submittedWords.sorted { $0.points > $1.points }) { scored in
                HStack {
                    Text(scored.word.uppercased())
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer()
                    Text("+\(scored.points)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))

                Divider()
                    .padding(.leading)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
