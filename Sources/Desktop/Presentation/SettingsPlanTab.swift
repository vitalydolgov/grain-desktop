import SwiftUI
import GrainDomain

struct SettingsPlanTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var planDraft = PlanDraft()

    var body: some View {
        Form {
            Section {
                Stepper("Phase A: \(planDraft.minutesA) min", value: $planDraft.minutesA, in: 1...90)
                Stepper("Phase B: \(planDraft.minutesB) min", value: $planDraft.minutesB, in: 1...90)
            }
            Section {
                VStack {
                    Text(totalDurationText)
                        .font(.title2.monospaced())
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text("Ends at \(estimatedEndText(from: context.date))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    HStack {
                        Text("Total")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Spacer()
                        StartButton(plan: makePlan())
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            planDraft = PlanDraft(from: await settings.timer.load())
        }
        .onChange(of: planDraft) { savePlan() }
    }

    private func makePlan() -> SessionPlan {
        let durationA = Duration.seconds(UInt64(planDraft.minutesA) * 60)
        let durationB = Duration.seconds(UInt64(planDraft.minutesB) * 60)
        return SessionPlan(intervals: [Interval(tag: .a, duration: durationA),
                                       Interval(tag: .b, duration: durationB)])
    }

    private func savePlan() {
        let plan = makePlan()
        Task {
            try? await settings.timer.save(plan)
            timerRuntime.plan = plan
        }
    }

    private var totalDuration: Duration { makePlan().totalDuration }

    private func estimatedEndText(from now: Date) -> String {
        let end = now.addingTimeInterval(TimeInterval(totalDuration.seconds))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: end)
    }

    private var totalDurationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        return formatter.string(from: TimeInterval(totalDuration.seconds)) ?? ""
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
        }
    }
}

private struct PlanDraft: Equatable {
    var minutesA = 25
    var minutesB = 5
}

private extension PlanDraft {
    init(from plan: SessionPlan) {
        minutesA = Int((plan.intervals.first { $0.tag == .a }?.duration.seconds ?? 1500) / 60)
        minutesB = Int((plan.intervals.first { $0.tag == .b }?.duration.seconds ?? 300) / 60)
    }
}
