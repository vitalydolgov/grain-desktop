import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                NavigationLink {
                    ValuePicker(title: "Total",
                                values: Array(stride(from: 40, through: 240, by: 5)),
                                unit: "min",
                                amount: $settings.configuration.totalMinutes)
                } label: {
                    SettingRow(title: "Total", value: "\(settings.configuration.totalMinutes) min")
                }
                if canToggleEndMode {
                    Toggle("Skip final break", isOn: Binding(
                        get: { !settings.configuration.endWithB },
                        set: { settings.configuration.endWithB = !$0 }
                    ))
                }
            }
            Section {
                if let plan = settings.configuration.makePlan() {
                    SplitPlanner(plan: plan)
                }
            }
        }
        .navigationTitle("Plan")
        .onChange(of: settings.configuration.totalMinutes) {
            settings.configuration = getFeasibleConfiguration(for: settings.configuration)
            apply()
        }
        .onChange(of: settings.configuration.endWithB) { apply() }
    }

    private var canToggleEndMode: Bool {
        settings.configuration.canPlan(endWithB: true) && settings.configuration.canPlan(endWithB: false)
    }

    private func getFeasibleConfiguration(for configuration: PlanConfiguration) -> PlanConfiguration {
        if configuration.canPlan(endWithB: true) {
            return PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: true)
        } else if configuration.canPlan(endWithB: false) {
            return PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: false)
        }
        return configuration
    }

    private func apply() {
        if let plan = settings.configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
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
