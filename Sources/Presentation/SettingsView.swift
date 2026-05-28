import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(TimerService.self) private var timerService
    @Environment(\.dismiss) private var dismiss

    @State private var partAName = Settings.defaultPartAName
    @State private var partBName = Settings.defaultPartBName
    @State private var partAMinutes = 25
    @State private var partBMinutes = 5
    @State private var totalRounds = Settings.defaultTotalRounds

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Stepper("Rounds: \(totalRounds)", value: $totalRounds, in: 1...20)
                }
                Section("Part A") {
                    TextField("Label", text: $partAName)
                    Stepper("Duration: \(partAMinutes) min", value: $partAMinutes, in: 1...60)
                }
                Section("Part B") {
                    TextField("Label", text: $partBName)
                    Stepper("Duration: \(partBMinutes) min", value: $partBMinutes, in: 1...60)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    timerService.settings = Settings(
                        partAName: partAName,
                        partBName: partBName,
                        partADuration: .seconds(UInt64(partAMinutes) * 60),
                        partBDuration: .seconds(UInt64(partBMinutes) * 60),
                        totalRounds: totalRounds
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 320)
        .onAppear {
            let s = timerService.settings
            partAName = s.partAName
            partBName = s.partBName
            partAMinutes = Int(s.partADuration.millis / 1000 / 60)
            partBMinutes = Int(s.partBDuration.millis / 1000 / 60)
            totalRounds = s.totalRounds
        }
    }
}
