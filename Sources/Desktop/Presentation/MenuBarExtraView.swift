import SwiftUI
import GrainDomain

struct MenuBarExtraView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        TimerActions(runStatus: timerRuntime.status)

        Divider()

        Button {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "floating-timer")
        } label: {
            Label("Floating", image: "pin.left")
        }

        Divider()

        Button {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        } label: {
            Label("Settings...", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("Quit", systemImage: "xmark.rectangle")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

private struct TimerActions: View {
    let runStatus: SessionStatus
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        switch runStatus {
        case .running:
            Button { timerRuntime.pause() } label: {
                Label("Pause", systemImage: "pause.fill")
            }
        case .paused:
            Button { timerRuntime.resume() } label: {
                Label("Resume", systemImage: "play.fill")
            }
        case .idle, .completed:
            Button { timerRuntime.start() } label: {
                Label("Start", systemImage: "play.fill")
            }
        }
        Button { timerRuntime.reset() } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
        }
        .disabled(runStatus == .idle)
    }
}
