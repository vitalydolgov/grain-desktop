import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var totalMinutes = 50
    @State private var endWithB = true

    private var configuration: PlanConfiguration {
        PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB)
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ValuePicker(title: "Total",
                                values: Array(stride(from: 40, through: 240, by: 5)),
                                unit: "min",
                                amount: $totalMinutes)
                } label: {
                    SettingRow(title: "Total", value: "\(totalMinutes) min")
                }
                if canToggleEndMode {
                    Toggle("Skip final break", isOn: Binding(
                        get: { !endWithB },
                        set: { endWithB = !$0 }
                    ))
                }
            }
            Section {
                if let plan = configuration.makePlan() {
                    SplitPlanner(plan: plan)
                }
            }
        }
        .navigationTitle("Plan")
        .task {
            let config = await settings.plan.load()
            totalMinutes = config.totalMinutes
            endWithB = config.endWithB
            selectFeasibleEndMode()
            updatePlan()
        }
        .onChange(of: totalMinutes) { selectFeasibleEndMode(); save() }
        .onChange(of: endWithB) { save() }
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

    private func save() {
        updatePlan()
        Task { try? await settings.plan.save(configuration) }
    }
}

private struct SettingRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ValuePicker: View {
    let title: String
    let values: [Int]
    let unit: String?
    @Binding var amount: Int

    var body: some View {
        Picker(title, selection: $amount) {
            ForEach(values, id: \.self) { value in
                Text(label(for: value)).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .navigationTitle(title)
    }

    private func label(for value: Int) -> String {
        guard let unit else { return "\(value)" }
        return "\(value) \(unit)"
    }
}

private struct SplitPlanner: View {
    let plan: SessionPlan

    var body: some View {
        VStack(spacing: 6) {
            SplitBar(intervals: plan.intervals, total: plan.totalDuration)
            HStack(spacing: 8) {
                PhaseKey(tag: .a)
                PhaseKey(tag: .b)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
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
        .frame(height: 14)
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
            .font(.system(size: 8, weight: .semibold))
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
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tag.color)
                .frame(width: 7, height: 7)
            Text(tag.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
