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
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(totalDurationText)
                            .font(.title2.monospaced())
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
                    let newPlan = SessionPlan(
                        nameA: nameA,
                        nameB: nameB,
                        durationA: .seconds(UInt64(minutesA) * 60),
                        durationB: .seconds(UInt64(minutesB) * 60),
                        totalRounds: totalRounds
                    )
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

    private var totalDurationText: String {
        let total = SessionPlan(
            nameA: nameA, nameB: nameB,
            durationA: .seconds(UInt64(minutesA) * 60),
            durationB: .seconds(UInt64(minutesB) * 60),
            totalRounds: totalRounds
        ).totalDuration
        let totalMinutes = Int(total.seconds / 60)
        return String(format: "%d:%02d'00", totalMinutes / 60, totalMinutes % 60)
    }
}
