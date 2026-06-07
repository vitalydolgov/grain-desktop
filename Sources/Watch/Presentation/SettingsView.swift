import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @AppStorage("planTotalMinutes") private var totalMinutes = PlanConfiguration.default.totalMinutes
    @AppStorage("planEndWithB") private var endWithB = PlanConfiguration.default.endWithB

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
            SplitBar(intervals: plan.intervals)
                .font(.system(size: 8))
                .frame(height: 14)
            SplitBarLegend(spacing: 8, dotSize: 7)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
