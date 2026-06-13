import SwiftUI
import GrainDomain

public struct SplitBar: View {
    let intervals: [Interval]

    public init(intervals: [Interval]) {
        self.intervals = intervals
    }

    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(Array(intervals.enumerated()), id: \.offset) { _, interval in
                    SplitSegment(interval: interval,
                                 width: width(for: interval, in: geometry.size.width))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var total: UInt64 {
        intervals.reduce(0) { $0 + $1.duration.millis }
    }

    private func width(for interval: Interval, in available: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        let usable = available - CGFloat(max(0, intervals.count - 1))
        return usable * CGFloat(interval.duration.millis) / CGFloat(total)
    }
}

private struct SplitSegment: View {
    let interval: Interval
    let width: CGFloat
    @Environment(AppTheme.self) private var theme

    var body: some View {
        Text("\(minutes)")
            .foregroundStyle(theme.splitBarTheme.labelColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .background(theme.splitBarTheme.color(for: interval.tag))
    }

    private var minutes: Int {
        Int((Double(interval.duration.millis) / 60_000).rounded())
    }
}

public struct SplitBarLegend: View {
    let spacing: CGFloat
    let dotSize: CGFloat

    public init(spacing: CGFloat, dotSize: CGFloat) {
        self.spacing = spacing
        self.dotSize = dotSize
    }

    public var body: some View {
        HStack(spacing: spacing) {
            PhaseKey(tag: .a, dotSize: dotSize)
            PhaseKey(tag: .b, dotSize: dotSize)
        }
    }
}

private struct PhaseKey: View {
    let tag: IntervalTag
    let dotSize: CGFloat
    @Environment(AppTheme.self) private var theme

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.splitBarTheme.color(for: tag))
                .frame(width: dotSize, height: dotSize)
            Text(tag == .a ? "Focus" : "Break")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
