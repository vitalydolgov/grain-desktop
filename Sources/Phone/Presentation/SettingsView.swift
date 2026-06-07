import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var totalMinutes = PlanConfiguration.default.totalMinutes
    @State private var endWithB = PlanConfiguration.default.endWithB

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
                if let plan = PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).makePlan() {
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
            if let plan = PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).makePlan() {
                timerRuntime.setPlan(plan)
            }
        }
        .onChange(of: totalMinutes) { selectFeasibleEndMode(); save() }
        .onChange(of: endWithB) { save() }
    }

    private var canToggleEndMode: Bool {
        PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).canPlan(endWithB: true)
            && PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).canPlan(endWithB: false)
    }

    private func selectFeasibleEndMode() {
        if PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).canPlan(endWithB: true) {
            endWithB = true
        } else if PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).canPlan(endWithB: false) {
            endWithB = false
        }
    }

    private func save() {
        if let plan = PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB).makePlan() {
            timerRuntime.setPlan(plan)
        }
        Task { try? await settings.plan.save(PlanConfiguration(totalMinutes: totalMinutes, endWithB: endWithB)) }
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
