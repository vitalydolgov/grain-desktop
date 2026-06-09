import SwiftUI
import GrainDomain

struct FloatingTimerView: View {
    @AppStorage("floatingWindowPinned") private var isPinned = true

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            TimerContent()
                .foregroundStyle(.primary)
        }
        .frame(width: 250)
        .overlay(alignment: .topTrailing) {
            PinButton(isPinned: $isPinned)
        }
        .background(FloatingWindowConfigurator(keepOnTop: isPinned))
        .ignoresSafeArea()
    }
}

@available(macOS 26.0, *)
struct GlassFloatingTimerView: View {
    @AppStorage("floatingWindowPinned") private var isPinned = true

    var body: some View {
        TimerContent()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) {
                PinButton(isPinned: $isPinned)
            }
            .foregroundStyle(.gray)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .background(FloatingWindowConfigurator(
                keepOnTop: isPinned,
                movableByBackground: true,
                transparentBackground: true
            ))
            .containerBackground(.clear, for: .window)
            .ignoresSafeArea()
    }
}

private struct PinButton: View {
    @Binding var isPinned: Bool

    var body: some View {
        Button {
            isPinned.toggle()
        } label: {
            Image(isPinned ? "pin.left.fill" : "pin.left")
                .resizable()
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .padding(6)
    }
}

private struct TimerContent: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 12) {
            IntervalDots(
                count: timerRuntime.plan.intervals.count,
                currentIndex: timerRuntime.currentIndex.index,
                status: timerRuntime.status,
                color: phaseColor,
                inactiveColor: inactiveDotColor
            )
            Text(format(timerRuntime.remainingTime))
                .font(.customMonospaced(size: 60))
                .animation(.snappy, value: timerRuntime.remainingTime)
            CompactControlPanel(status: timerRuntime.status) { openSettings() }
        }
    }

    private var phaseColor: Color {
        let idx = timerRuntime.currentIndex
        let intervals = timerRuntime.plan.intervals
        guard idx.index < intervals.count else { return Color(white: 0.3) }
        return switch intervals[idx.index].tag {
        case .a: Color(red: 0.23, green: 0.62, blue: 1.0)
        case .b: Color(red: 0.96, green: 0.72, blue: 0.16)
        }
    }

    private var inactiveDotColor: Color {
        (colorScheme == .dark ? Color.white : Color.black).opacity(0.25)
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
