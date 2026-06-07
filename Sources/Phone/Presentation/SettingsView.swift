import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Stepper("Total: \(settings.configuration.totalMinutes) min",
                        value: $settings.configuration.totalMinutes, in: 40...240, step: 5)
                Toggle("Skip final break", isOn: Binding(
                    get: { !settings.configuration.endWithB },
                    set: { settings.configuration.endWithB = !$0 }
                ))
                .disabled(!canToggleEndMode)
            }
            Section {
                if let plan = settings.configuration.makePlan() {
                    SplitPlanner(plan: plan)
                }
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
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

private struct SplitPlanner: View {
    let plan: SessionPlan

    var body: some View {
        VStack(spacing: 10) {
            SplitBar(intervals: plan.intervals)
                .font(.system(size: 10))
                .frame(height: 20)
            SplitBarLegend()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
