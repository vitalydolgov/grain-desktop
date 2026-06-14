import SwiftUI
import GrainDomain
import GrainApplication
import GrainComponents

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var planConfiguration = PlanConfiguration.default

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ValuePicker(title: "Total",
                                values: Array(stride(from: 40, through: 240, by: 5)),
                                unit: "min",
                                amount: $planConfiguration.totalMinutes)
                } label: {
                    SettingRow(title: "Total", value: "\(planConfiguration.totalMinutes) min")
                }
                Toggle("Skip final break", isOn: Binding(
                    get: { !planConfiguration.endWithB },
                    set: { planConfiguration.endWithB = !$0 }
                ))
                .disabled(!canToggleEndMode)
            }
            Section {
                if let plan = planConfiguration.makePlan() {
                    SplitPlanner(plan: plan)
                }
            }
        }
        .navigationTitle("Plan")
        .onChange(of: settings.planConfiguration, initial: true) {
            planConfiguration = settings.planConfiguration
        }
        .onChange(of: planConfiguration) {
            if planConfiguration.isFeasible {
                saveConfiguration(planConfiguration)
            } else if let alternative = feasibleAlternative(for: planConfiguration) {
                planConfiguration = alternative
            }
        }
    }

    private var canToggleEndMode: Bool {
        planConfiguration.canPlan(endWithB: true) && planConfiguration.canPlan(endWithB: false)
    }

    private func feasibleAlternative(for configuration: PlanConfiguration) -> PlanConfiguration? {
        let alternative = PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: !configuration.endWithB)
        return alternative.isFeasible ? alternative : nil
    }

    private func saveConfiguration(_ configuration: PlanConfiguration) {
        guard configuration != settings.planConfiguration else { return }
        if let plan = configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
        settings.planConfiguration = configuration
        Task { await settings.save() }
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
