import SwiftUI
import GrainDomain
import GrainApplication

struct TimerView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ProgressRing(fraction: phaseRemainingFraction, color: phaseColor)
                .padding(-6)
            VStack(spacing: 2) {
                if let kind = timerRuntime.currentLocation?.kind {
                    Text(phaseLabel(kind))
                        .font(.custom("Urbanist", size: 17, relativeTo: .headline).weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(phaseColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(format(timerRuntime.remainingTime))
                    .font(.custom("SUSE Mono", size: 40))
                    .foregroundStyle(.white)
                if let round = roundText {
                    Text(round)
                        .font(.custom("Urbanist", size: 15, relativeTo: .subheadline).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 28)
        }
        .animation(.linear(duration: 0.3), value: phaseRemainingFraction)
    }

    private var phaseRemainingFraction: Double {
        guard let location = timerRuntime.currentLocation else { return 1 }
        let total = timerRuntime.plan.duration(for: location).millis
        guard total > 0 else { return 1 }
        let clamped = min(timerRuntime.remainingTime.millis, total)
        return Double(clamped) / Double(total)
    }

    private func phaseLabel(_ kind: PhaseKind) -> String {
        switch kind {
        case .phaseA: "Phase A"
        case .phaseB: "Phase B"
        }
    }

    private var roundText: String? {
        guard let cycle = timerRuntime.currentLocation?.cycle else { return nil }
        return "Round \(cycle) of \(timerRuntime.plan.totalCycles)"
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var phaseColor: Color {
        switch timerRuntime.currentLocation?.kind {
        case .phaseA: Color(red: 0.23, green: 0.62, blue: 1.0)
        case .phaseB: Color(red: 0.96, green: 0.72, blue: 0.16)
        case nil: Color(white: 0.3)
        }
    }
}

private struct ProgressRing: View {
    let fraction: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .shadow(color: color.opacity(0.7), radius: 6)
                .shadow(color: color.opacity(0.45), radius: 13)
                .shadow(color: color.opacity(0.25), radius: 20)
                .rotationEffect(.degrees(-90))
        }
    }
}
