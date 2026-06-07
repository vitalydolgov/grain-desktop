import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var totalMinutes = PlanConfiguration.default.totalMinutes
    @State private var endWithB = PlanConfiguration.default.endWithB

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
                if let plan = PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).makePlan() {
                    SplitPlanner(plan: plan)
                }
            }
        }
        .navigationTitle("Plan")
        .task {
            let loaded = await settings.plan.load()
            let configuration = selectFeasibleEndMode(for: loaded)
            if let plan = configuration.makePlan() {
                timerRuntime.setPlan(plan)
            }
            totalMinutes = configuration.totalMinutes
            endWithB = configuration.endWithB
        }
        .onChange(of: totalMinutes) {
            let configuration = selectFeasibleEndMode(for: PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB))
            endWithB = configuration.endWithB
            save(configuration)
        }
        .onChange(of: endWithB) {
            save(PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB))
        }
    }

    private var canToggleEndMode: Bool {
        PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).canPlan(endWithB: true)
            && PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).canPlan(endWithB: false)
    }

    private func selectFeasibleEndMode(for configuration: PlanConfiguration) -> PlanConfiguration {
        if configuration.canPlan(endWithB: true) {
            return PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: true)
        } else if configuration.canPlan(endWithB: false) {
            return PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: false)
        }
        return configuration
    }

    private func save(_ configuration: PlanConfiguration) {
        if let plan = configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
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
            SplitBar(intervals: plan.intervals)
                .font(.system(size: 8))
                .frame(height: 14)
            SplitBarLegend(spacing: 8, dotSize: 7)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
