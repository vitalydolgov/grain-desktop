import SwiftUI
import GrainDomain

struct SplitBar: View {
    let intervals: [Interval]

    var body: some View {
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

    var body: some View {
        Text("\(minutes)")
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .background(interval.tag.color)
    }

    private var minutes: Int {
        Int((Double(interval.duration.millis) / 60_000).rounded())
    }
}

struct SplitBarLegend: View {
    var spacing: CGFloat = 12
    var dotSize: CGFloat = 9

    var body: some View {
        HStack(spacing: spacing) {
            PhaseKey(tag: .a, dotSize: dotSize)
            PhaseKey(tag: .b, dotSize: dotSize)
        }
    }
}

private struct PhaseKey: View {
    let tag: IntervalTag
    var dotSize: CGFloat = 9

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tag.color)
                .frame(width: dotSize, height: dotSize)
            Text(tag.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
