import SwiftUI
import GrainDomain
import GrainApplication
import GrainComponents

struct TimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PhaseLabel(face: face, theme: theme)
                    .padding(.top, 16)

                Spacer()

                Text(format(timerRuntime.remainingTime))
                    .font(.customMonospaced(size: 88))
                    .foregroundStyle(theme.timerTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                IntervalDots(count: timerRuntime.plan.intervals.count,
                             currentIndex: timerRuntime.currentIndex.index,
                             status: timerRuntime.status,
                             color: theme.accentColor)
                    .padding(.top, 24)

                Spacer()

                ControlBar(theme: theme)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 32)

            VStack {
                HStack {
                    Spacer()
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(theme.controlIconColor)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .animation(.easeInOut(duration: 0.4), value: theme.labelColor)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private var face: TimerFace {
        TimerFace(status: timerRuntime.status, tag: currentTag)
    }

    private var theme: PhaseTheme {
        face.theme(colorScheme)
    }

    private var currentTag: IntervalTag? {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return nil }
        return intervals[idx.index].tag
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct PhaseLabel: View {
    let face: TimerFace
    let theme: PhaseTheme

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(theme.labelColor)
                .frame(width: 7, height: 7)
                .shadow(color: theme.labelColor.opacity(0.5), radius: 2.5, x: 0, y: 1.5)
            Text(face.label.uppercased())
                .font(.customRegular(size: 15))
                .tracking(4)
                .foregroundStyle(theme.labelColor)
                .lineLimit(1)
        }
    }
}

private struct ControlBar: View {
    let theme: PhaseTheme
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        HStack(spacing: 28) {
            switch timerRuntime.status {
            case .running, .paused:
                Color.clear.frame(width: 64, height: 64)
            case .idle, .completed:
                EmptyView()
            }

            ControlBarButton(icon: timerRuntime.status == .running ? "pause.fill" : "play.fill",
                         size: 88, iconSize: 30,
                         surface: theme.accentColor,
                         foreground: theme.onAccentColor,
                         glow: theme.accentColor,
                         action: toggleTimer)

            switch timerRuntime.status {
            case .running:
                ControlBarButton(icon: "forward.end.fill",
                             size: 64, iconSize: 19,
                             surface: theme.controlSurfaceColor,
                             foreground: theme.controlIconColor,
                             action: timerRuntime.skip)
            case .paused:
                ControlBarButton(icon: "arrow.counterclockwise",
                             size: 64, iconSize: 22,
                             surface: theme.controlSurfaceColor,
                             foreground: theme.controlIconColor,
                             action: timerRuntime.reset)
            case .idle, .completed:
                EmptyView()
            }
        }
    }

    private func toggleTimer() {
        switch timerRuntime.status {
        case .running: timerRuntime.pause()
        case .paused: timerRuntime.resume()
        case .idle, .completed: timerRuntime.start()
        }
    }
}

private struct ControlBarButton: View {
    let icon: String
    let size: CGFloat
    let iconSize: CGFloat
    let surface: Color
    let foreground: Color
    var glow: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(surface)
                .frame(width: size, height: size)
                .shadow(color: (glow ?? .black).opacity(glow == nil ? 0.08 : 0.35),
                        radius: glow == nil ? 6 : 14,
                        x: 0, y: glow == nil ? 3 : 8)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(foreground)
                }
        }
        .buttonStyle(.plain)
    }
}
