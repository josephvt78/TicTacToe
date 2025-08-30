// MARK: - TicTacToe Multiplatform (SwiftUI)
// Works on iOS, iPadOS, and macOS with a single codebase.
// Xcode 15+ / Swift 5.9+

import SwiftUI

// MARK: - App Entry Point
@main
struct TicTacToeApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
        .commands { // macOS menu command for Reset
            CommandMenu("Game") {
                Button("New Game") {
                    NotificationCenter.default.post(name: .newGame, object: nil)
                }
                .keyboardShortcut("r")
            }
        }
    }
}

