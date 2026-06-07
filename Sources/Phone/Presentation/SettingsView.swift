import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RuntimeProxy.self) private var timerRuntime
    @AppStorage("planTotalMinutes") private var totalMinutes = 60
    @AppStorage("planEndWithB") private var endWithB = true

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
