//
//  ContentView.swift
//  TicTacToe
//
//  Created by Joseph Varghese on 8/29/25.
//

import SwiftUI
import RealityKit

// MARK: - Model
enum Player: String, Codable, CaseIterable, Equatable {
    case x = "X"
    case o = "O"

    var next: Player { self == .x ? .o : .x }
}

struct GameState: Equatable, Codable {
    var board: [Player?] = Array(repeating: nil, count: 9)
    var current: Player = .x
    var winner: Player? = nil

    var isBoardFull: Bool { !board.contains(where: { $0 == nil }) }
    var isDraw: Bool { winner == nil && isBoardFull }

    mutating func reset() {
        board = Array(repeating: nil, count: 9)
        current = .x
        winner = nil
    }

    mutating func makeMove(at index: Int) {
        guard (0..<9).contains(index), winner == nil, board[index] == nil else { return }
        board[index] = current
        if let w = checkWinner() {
            winner = w
        } else if !isBoardFull {
            current = current.next
        }
    }

    func checkWinner() -> Player? {
        let lines = [
            [0,1,2],[3,4,5],[6,7,8], // rows
            [0,3,6],[1,4,7],[2,5,8], // cols
            [0,4,8],[2,4,6]          // diagonals
        ]
        for line in lines {
            if let p = board[line[0]], board[line[1]] == p, board[line[2]] == p {
                return p
            }
        }
        return nil
    }
}

// MARK: - ViewModel (Observable)
@Observable
final class GameViewModel {
    var state = GameState()

    func tap(_ index: Int) {
        state.makeMove(at: index)
    }

    func reset() { state.reset() }
}

// MARK: - Views
struct GameView: View {
    @State private var vm = GameViewModel()
    @State private var showResult = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 16) {
            header
            board
            footer
        }
        .padding(24)
        .frame(minWidth: 320, idealWidth: 420)
        .onChange(of: vm.state.winner) { _, new in
            showResult = new != nil || vm.state.isDraw
        }
        .alert(resultTitle, isPresented: $showResult) {
            Button("New Game") { vm.reset() }
            Button("OK", role: .cancel) { }
        } message: {
            Text(resultMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newGame)) { _ in
            vm.reset()
        }
        .toolbar { toolbar }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                vm.reset()
            } label: {
                Label("New Game", systemImage: "arrow.clockwise")
            }
            .help("Start a new game")
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Tic‑Tac‑Toe")
                .font(.largeTitle).bold()
            Text(statusText)
                .font(.title3)
                .accessibilityLabel("Status: \(statusText)")
        }
    }

    private var board: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<9, id: \.self) { idx in
                SquareView(symbol: vm.state.board[idx]?.rawValue)
                    .onTapGesture { vm.tap(idx) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Cell \(idx + 1)")
                    .accessibilityHint(vm.state.board[idx] == nil ? "Place \(vm.state.current.rawValue)" : "Occupied")
            }
        }
        .padding(4)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                vm.reset()
            } label: {
                Label("New Game", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Text("Current: \(vm.state.current.rawValue)")
                .font(.headline)
        }
    }

    private var statusText: String {
        if let w = vm.state.winner { return "Winner: \(w.rawValue)" }
        if vm.state.isDraw { return "Draw" }
        return "Turn: \(vm.state.current.rawValue)"
    }

    private var resultTitle: String {
        if vm.state.isDraw { return "It's a draw" }
        if let w = vm.state.winner { return "\(w.rawValue) wins!" }
        return "Game Over"
    }

    private var resultMessage: String {
        if vm.state.isDraw { return "No more moves left." }
        if let w = vm.state.winner { return "Congratulations, Player \(w.rawValue)!" }
        return "Thanks for playing."
    }
}

struct SquareView: View {
    let symbol: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 16).fill(.thickMaterial))
                .aspectRatio(1, contentMode: .fit)
            Text(symbol ?? "")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.5)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#Preview("Game") {
    GameView()
}

// MARK: - Notifications
extension Notification.Name {
    static let newGame = Notification.Name("NewGameNotification")
}
