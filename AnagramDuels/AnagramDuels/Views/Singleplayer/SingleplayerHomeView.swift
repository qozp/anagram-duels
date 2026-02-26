import SwiftUI

struct SingleplayerHomeView: View {
    @EnvironmentObject var vm: SingleplayerViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        LevelSelectView().environmentObject(vm)
                    } label: {
                        ModeRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "Levels",
                            subtitle: "Progress through pre-set words"
                        )
                    }

                    NavigationLink {
                        PracticeModeView().environmentObject(vm)
                    } label: {
                        ModeRow(
                            icon: "shuffle",
                            iconColor: .blue,
                            title: "Practice",
                            subtitle: "Random word, no pressure"
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Singleplayer")
            .onAppear {
                Task { await vm.loadLevels() }
            }
        }
    }
}

// MARK: - Level Select
struct LevelSelectView: View {
    @EnvironmentObject var vm: SingleplayerViewModel

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading levels…")
            } else if vm.levels.isEmpty {
                ContentUnavailableView("No levels yet", systemImage: "star.slash")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(vm.levels) { level in
                            NavigationLink {
                                GameBoardView(viewModel: GameViewModel(context: vm.levelContext(level)))
                            } label: {
                                LevelCell(level: level)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Levels")
    }
}

struct LevelCell: View {
    let level: LevelModel

    var body: some View {
        VStack(spacing: 4) {
            Text("\(level.levelNumber)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            if let theme = level.themeName {
                Text(theme)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 72, height: 72)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Practice Mode
struct PracticeModeView: View {
    @EnvironmentObject var vm: SingleplayerViewModel
    @State private var readyToPlay = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shuffle")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Practice Mode")
                .font(.title.bold())
            Text("A random 6-letter word will be chosen. No scoring limits or progression — just practice!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Start Practice") {
                vm.preparePracticeGame()
                readyToPlay = true
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Practice")
        .navigationDestination(isPresented: $readyToPlay) {
            GameBoardView(viewModel: GameViewModel(context: vm.practiceContext()))
        }
    }
}

// MARK: - Mode Row
struct ModeRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
