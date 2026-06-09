import SwiftUI
import GrainDomain

struct MenuBarView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @Environment(AppSettings.self) private var settings

    var body: some View {
        switch settings.preferences.menuBarMode {
        case .time:
            Text(format(timerRuntime.remainingTime))
        case .minutes:
            Text(formatMinutes(timerRuntime.remainingTime))
        case .icon:
            ProgressRingIcon()
        }
    }

    private func format(_ duration: Duration) -> String {
        let total = duration.seconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func formatMinutes(_ duration: Duration) -> String {
        let minutes = Int(ceil(Double(duration.seconds) / 60))
        return "\(minutes)m"
    }
}

private struct ProgressRingIcon: View {
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        Image(nsImage: image)
    }

    private var image: NSImage {
        let renderer = ImageRenderer(content: ring)
        renderer.scale = 2
        let nsImage = renderer.nsImage ?? NSImage()
        nsImage.isTemplate = true
        return nsImage
    }

    private var ring: some View {
        let lineWidth: CGFloat = 1.5
        let p = progress
        return Canvas { context, size in
            let inset = lineWidth / 2
            let rect = CGRect(x: inset, y: inset, width: size.width - lineWidth, height: size.height - lineWidth)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(rect.width, rect.height) / 2
            context.stroke(Path(ellipseIn: rect), with: .color(.primary.opacity(0.2)), lineWidth: lineWidth)
            let remaining = 1 - p
            if remaining > 0 {
                var arc = Path()
                arc.addArc(center: center, radius: radius,
                           startAngle: .degrees(-90),
                           endAngle: .degrees(-90 + 360 * remaining),
                           clockwise: false)
                context.stroke(arc, with: .color(.primary),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .frame(width: 16, height: 16)
    }

    private var progress: Double {
        guard timerRuntime.status == .running || timerRuntime.status == .paused else { return 0 }
        let intervals = timerRuntime.plan.intervals
        let idx = timerRuntime.currentIndex.index
        guard idx < intervals.count else { return 0 }
        let total = intervals[idx].duration.seconds
        guard total > 0 else { return 0 }
        let remaining = timerRuntime.remainingTime.seconds
        let elapsed = total > remaining ? total - remaining : 0
        return Double(elapsed) / Double(total)
    }
}
