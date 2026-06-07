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
