import SwiftUI
import GrainDomain
import GrainComponents

struct SettingsPlanTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var configuration = PlanConfiguration.default

    var body: some View {
        Form {
            Section {
                Stepper("Total: \(configuration.totalMinutes) min",
                        value: $configuration.totalMinutes, in: 40...240, step: 5)
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Skip final break", isOn: Binding(
                        get: { !configuration.endWithB },
                        set: { configuration.endWithB = !$0 }
                    ))
                    .disabled(toggleLocked)
                    if toggleLocked {
                        Text(skipBreakHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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

    private var skipBreakHint: String {
        configuration.endWithB ? "No optimal split without final break" : "No optimal split with final break"
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
                SplitBar(intervals: plan.intervals)
                    .font(.system(size: 10))
                    .frame(height: 20)
                SplitBarLegend(spacing: 12, dotSize: 9)
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
            timerRuntime.handle(.start)
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Text("Start")
                Image(systemName: "play.circle.fill")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(red: 0.23, green: 0.62, blue: 1.0))
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
