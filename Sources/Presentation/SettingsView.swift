import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var totalRounds = SessionPlan.default.totalRounds
    @State private var nameA = SessionPlan.default.nameA
    @State private var minutesA = 25
    @State private var nameB = SessionPlan.default.nameB
    @State private var minutesB = 5
    @State private var selectedPart = 0
    let settings: TimerSettings
    let onSave: (SessionPlan) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Stepper("Repeat: \(totalRounds)", value: $totalRounds, in: 1...20)
                }
                Section {
                    HStack {
                        Spacer()
                        Picker("", selection: $selectedPart) {
                            Text("Part A").tag(0)
                            Text("Part B").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                        Spacer()
                    }
                    if selectedPart == 0 {
                        TextField("Label", text: $nameA)
                        Stepper("Duration: \(minutesA) min", value: $minutesA, in: 1...60)
                    } else {
                        TextField("Label", text: $nameB)
                        Stepper("Duration: \(minutesB) min", value: $minutesB, in: 1...60)
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
                            StartButton(plan: makePlan(), settings: settings, onSave: onSave)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    let newPlan = makePlan()
                    Task {
                        try? await settings.save(newPlan)
                        onSave(newPlan)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 300, height: 350)
        .navigationTitle("Timer Settings")
        .task {
            let plan = await settings.load()
            nameA = plan.nameA
            nameB = plan.nameB
            minutesA = Int(plan.durationA.seconds / 60)
            minutesB = Int(plan.durationB.seconds / 60)
            totalRounds = plan.totalRounds
        }
    }

    private func makePlan() -> SessionPlan {
        SessionPlan(
            nameA: nameA, nameB: nameB,
            durationA: .seconds(UInt64(minutesA) * 60),
            durationB: .seconds(UInt64(minutesB) * 60),
            totalRounds: totalRounds
        )
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
    let settings: TimerSettings
    let onSave: (SessionPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        Button {
            Task {
                try? await settings.save(plan)
                onSave(plan)
                timerRuntime.start()
            }
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Text("Start")
                Image(systemName: "play.circle.fill")
            }
        }
    }
}
