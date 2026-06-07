import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var configuration = PlanConfiguration.default

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ValuePicker(title: "Total",
                                values: Array(stride(from: 40, through: 240, by: 5)),
                                unit: "min",
                                amount: $configuration.totalMinutes)
                } label: {
                    SettingRow(title: "Total", value: "\(configuration.totalMinutes) min")
                }
                if canToggleEndMode {
                    Toggle("Skip final break", isOn: Binding(
                        get: { !configuration.endWithB },
                        set: { configuration.endWithB = !$0 }
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
        .onChange(of: settings.configuration, initial: true) {
            configuration = settings.configuration
        }
        .onChange(of: configuration) {
            if configuration.isFeasible {
                saveConfiguration(configuration)
            } else if let alternative = feasibleAlternative(for: configuration) {
                configuration = alternative
                saveConfiguration(alternative)
            }
        }
    }

    private var canToggleEndMode: Bool {
        configuration.canPlan(endWithB: true) && configuration.canPlan(endWithB: false)
    }

    private func feasibleAlternative(for configuration: PlanConfiguration) -> PlanConfiguration? {
        let alternative = PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: !configuration.endWithB)
        return alternative.isFeasible ? alternative : nil
    }

    private func saveConfiguration(_ configuration: PlanConfiguration) {
        guard configuration != settings.configuration else { return }
        if let plan = configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
        settings.configuration = configuration
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
