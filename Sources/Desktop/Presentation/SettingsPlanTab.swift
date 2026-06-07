import SwiftUI
import GrainDomain

struct SettingsPlanTab: View {
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
                .disabled(toggleLocked)
            }
            Section {
                if let plan = configuration.makePlan() {
                    PlanSummary(plan: plan)
                }
            }
        }
        .formStyle(.grouped)
        .task {
            configuration = await settings.plan.load()
            selectFeasibleMode()
        }
        .onChange(of: configuration.totalMinutes) { selectFeasibleMode() }
        .onChange(of: configuration) { saveConfiguration() }
    }

    private var toggleLocked: Bool {
        !(configuration.canPlan(endWithB: true) && configuration.canPlan(endWithB: false))
    }

    private func selectFeasibleMode() {
        if configuration.canPlan(endWithB: true) {
            configuration.endWithB = true
        } else if configuration.canPlan(endWithB: false) {
            configuration.endWithB = false
        }
    }

    private func saveConfiguration() {
        let configuration = configuration
        Task {
            try? await settings.plan.save(configuration)
            if let plan = configuration.makePlan() {
                timerRuntime.plan = plan
            }
        }
    }
}

private struct PlanSummary: View {
    let plan: SessionPlan

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {
                SplitBar(intervals: plan.intervals, total: plan.totalDuration)
                HStack(spacing: 12) {
                    PhaseKey(tag: .a)
                    PhaseKey(tag: .b)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text("Ends at \(estimatedEndText(from: context.date))")
                        .fontWeight(.medium)
                }
                Spacer()
                StartButton(plan: plan)
            }
        }
    }

    private func estimatedEndText(from now: Date) -> String {
        let end = now.addingTimeInterval(TimeInterval(plan.totalDuration.seconds))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: end)
    }
}

private struct StartButton: View {
    let plan: SessionPlan
    @Environment(\.dismiss) private var dismiss
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        Button {
            timerRuntime.plan = plan
            timerRuntime.start()
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Text("Start")
                Image(systemName: "play.circle.fill")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(IntervalTag.a.color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.white.opacity(0.3), lineWidth: 1)
            }
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}
