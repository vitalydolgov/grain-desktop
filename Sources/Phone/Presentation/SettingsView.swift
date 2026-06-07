import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RuntimeProxy.self) private var timerRuntime
    @AppStorage("planTotalMinutes") private var totalMinutes = 50
    @AppStorage("planEndWithB") private var endWithB = true

    private var configuration: PlanConfiguration {
        PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB)
    }

    var body: some View {
        Form {
            Section {
                Stepper("Total: \(totalMinutes) min",
                        value: $totalMinutes, in: 40...240, step: 5)
                Toggle("Skip final break", isOn: Binding(
                    get: { !endWithB },
                    set: { endWithB = !$0 }
                ))
                .disabled(!canToggleEndMode)
            }
            Section {
                if let plan = configuration.makePlan() {
                    SplitPlanner(plan: plan)
                }
            }
        }
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { selectFeasibleEndMode(); updatePlan() }
        .onChange(of: totalMinutes) { selectFeasibleEndMode(); updatePlan() }
        .onChange(of: endWithB) { updatePlan() }
    }

    private var canToggleEndMode: Bool {
        configuration.canPlan(endWithB: true) && configuration.canPlan(endWithB: false)
    }

    private func selectFeasibleEndMode() {
        if configuration.canPlan(endWithB: true) {
            endWithB = true
        } else if configuration.canPlan(endWithB: false) {
            endWithB = false
        }
    }

    private func updatePlan() {
        if let plan = configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
    }
}

private struct SplitPlanner: View {
    let plan: SessionPlan

    var body: some View {
        VStack(spacing: 10) {
            SplitBar(intervals: plan.intervals, total: plan.totalDuration)
            HStack(spacing: 12) {
                PhaseKey(tag: .a)
                PhaseKey(tag: .b)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

private struct SplitBar: View {
    let intervals: [Interval]
    let total: Duration

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(Array(intervals.enumerated()), id: \.offset) { _, interval in
                    SplitSegment(interval: interval,
                                 width: width(for: interval, in: geometry.size.width))
                }
            }
        }
        .frame(height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func width(for interval: Interval, in available: CGFloat) -> CGFloat {
        guard total.millis > 0 else { return 0 }
        let usable = available - CGFloat(max(0, intervals.count - 1))
        return usable * CGFloat(interval.duration.millis) / CGFloat(total.millis)
    }
}

private struct SplitSegment: View {
    let interval: Interval
    let width: CGFloat

    var body: some View {
        Text("\(minutes)")
            .font(.system(size: 10, weight: .semibold))
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

private struct PhaseKey: View {
    let tag: IntervalTag

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tag.color)
                .frame(width: 9, height: 9)
            Text(tag.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
