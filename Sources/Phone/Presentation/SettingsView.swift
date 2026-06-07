import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var totalMinutes = PlanConfiguration.default.totalMinutes
    @State private var endWithB = PlanConfiguration.default.endWithB

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
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
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
