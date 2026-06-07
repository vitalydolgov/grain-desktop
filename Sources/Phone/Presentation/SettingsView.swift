import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var configuration = PlanConfiguration.default

    var body: some View {
        Form {
            Section {
                Stepper("Total: \(configuration.totalMinutes) min",
                        value: $configuration.totalMinutes, in: 40...240, step: 5)
                Toggle("Skip final break", isOn: Binding(
                    get: { !configuration.endWithB },
                    set: { configuration.endWithB = !$0 }
                ))
                .disabled(!canToggleEndMode)
            }
            Section {
                if let plan = configuration.makePlan() {
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
        .onChange(of: settings.configuration, initial: true) {
            configuration = settings.configuration
        }
        .onChange(of: configuration) {
            let feasible = getFeasibleConfiguration(for: configuration)
            guard feasible == configuration else {
                configuration = feasible
                return
            }
            apply()
        }
    }

    private var canToggleEndMode: Bool {
        configuration.canPlan(endWithB: true) && configuration.canPlan(endWithB: false)
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
        guard configuration != settings.configuration else { return }
        if let plan = configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
        settings.configuration = configuration
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
