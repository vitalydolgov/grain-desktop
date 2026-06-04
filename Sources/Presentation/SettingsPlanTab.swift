import SwiftUI
import GrainDomain

struct SettingsPlanTab: View {
    @Binding var displayPrefs: DisplayPreferences
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var planDraft = PlanDraft()
    @State private var selectedPhase = 0
    @State private var showCycleLengthHelp = false

    var body: some View {
        Form {
            Section {
                Stepper("Repeat: \(planDraft.totalCycles)", value: $planDraft.totalCycles, in: 1...6)
            }
            Section {
                HStack {
                    Spacer()
                    Picker("", selection: $selectedPhase) {
                        Text("Phase A").tag(0)
                        Text("Phase B").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    Spacer()
                }
                if selectedPhase == 0 {
                    TextField("Label", text: $displayPrefs.phaseLabels.phaseA)
                    Stepper("Duration: \(planDraft.minutesA) min", value: $planDraft.minutesA, in: 1...60)
                } else {
                    TextField("Label", text: $displayPrefs.phaseLabels.phaseB)
                    Stepper("Duration: \(planDraft.minutesB) min", value: $planDraft.minutesB, in: 1...60)
                }
            }
            Section {
                HStack {
                    HStack(spacing: 4) {
                        Text("Cycle length")
                        Button {
                            showCycleLengthHelp.toggle()
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showCycleLengthHelp) {
                            Text("Ratio controls how quickly phase durations scale across cycles.")
                                .padding()
                                .frame(width: 200)
                        }
                    }
                    Spacer()
                    Text(cycleLengthDescription).foregroundStyle(.secondary)
                    Stepper("", value: $planDraft.cycleLengthMultiplier, in: 0.7...1.3, step: 0.1)
                        .labelsHidden()
                }
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
        SessionPlan(
            durationA: .seconds(UInt64(planDraft.minutesA) * 60),
            durationB: .seconds(UInt64(planDraft.minutesB) * 60),
            totalCycles: planDraft.totalCycles,
            curve: planDraft.curve
        )
    }

    private func savePlan() {
        let plan = makePlan()
        Task {
            try? await settings.timer.save(plan)
            timerRuntime.plan = plan
        }
    }

    private var totalDuration: Duration { makePlan().totalDuration }

    private var cycleLengthDescription: String {
        let m = planDraft.cycleLengthMultiplier
        let mode = m > 1.0 + 0.05 ? "Growth" : m < 1.0 - 0.05 ? "Decay" : "Constant"
        return String(format: "%@ ×%.1f", mode, m)
    }

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
    var totalCycles = SessionPlan.default.totalCycles
    var minutesA = 50
    var minutesB = 10
    var cycleLengthMultiplier: Double = 1.0

    var curve: Curve {
        if abs(cycleLengthMultiplier - 1.0) < 0.05 { return .constant }
        return cycleLengthMultiplier > 1.0
            ? .growth(ratio: cycleLengthMultiplier)
            : .decay(ratio: 2.0 - cycleLengthMultiplier)
    }

    static func multiplier(from curve: Curve) -> Double {
        switch curve {
        case .constant:           1.0
        case .growth(let ratio):  ratio
        case .decay(let ratio):   2.0 - ratio
        }
    }
}

private extension PlanDraft {
    init(from plan: SessionPlan) {
        totalCycles = plan.totalCycles
        minutesA = Int(plan.durationA.seconds / 60)
        minutesB = Int(plan.durationB.seconds / 60)
        cycleLengthMultiplier = Self.multiplier(from: plan.curve)
    }
}
