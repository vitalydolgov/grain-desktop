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
    let settings: TimerSettings
    let onSave: (SessionPlan) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Stepper("Rounds: \(totalRounds)", value: $totalRounds, in: 1...20)
                }
                Section("Part A") {
                    TextField("Label", text: $nameA)
                    Stepper("Duration: \(minutesA) min", value: $minutesA, in: 1...60)
                }
                Section("Part B") {
                    TextField("Label", text: $nameB)
                    Stepper("Duration: \(minutesB) min", value: $minutesB, in: 1...60)
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
        .frame(width: 320)
        .task {
            let plan = await settings.load()
            nameA = plan.nameA
            nameB = plan.nameB
            minutesA = Int(plan.durationA.millis / 1000 / 60)
            minutesB = Int(plan.durationB.millis / 1000 / 60)
            totalRounds = plan.totalRounds
        }
    }
}
