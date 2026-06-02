import SwiftUI
import GrainDomain

struct SettingsView: View {
    let settings: GrainAppSettings
    let onSave: (SessionPlan) -> Void
    let onDisplaySave: (DisplayPreferences) -> Void
    @State private var totalRounds = SessionPlan.default.totalRounds
    @State private var nameA = PhaseLabels.default.nameA
    @State private var minutesA = 25
    @State private var nameB = PhaseLabels.default.nameB
    @State private var minutesB = 5
    @State private var selectedPart = 0
    @State private var menuBarFormat: MenuBarLabelFormat = .time
    @State private var isLoaded = false

    var body: some View {
        TabView {
            TimerTab(
                plan: makePlan(),
                settings: settings.timer,
                onSave: onSave,
                totalRounds: $totalRounds,
                nameA: $nameA,
                nameB: $nameB,
                minutesA: $minutesA,
                minutesB: $minutesB,
                selectedPart: $selectedPart
            )
            .tabItem { Label("Timer", systemImage: "timer") }

            AppearanceTab(menuBarFormat: $menuBarFormat)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 300, height: 300)
        .task {
            let plan = await settings.timer.load()
            minutesA = Int(plan.durationA.seconds / 60)
            minutesB = Int(plan.durationB.seconds / 60)
            totalRounds = plan.totalRounds
            let prefs = await settings.display.load()
            menuBarFormat = prefs.menuBarLabelFormat
            nameA = prefs.phaseLabels.nameA
            nameB = prefs.phaseLabels.nameB
            isLoaded = true
        }
        .onChange(of: totalRounds) { _, _ in savePlan() }
        .onChange(of: minutesA) { _, _ in savePlan() }
        .onChange(of: minutesB) { _, _ in savePlan() }
        .onChange(of: nameA) { _, _ in saveDisplay() }
        .onChange(of: nameB) { _, _ in saveDisplay() }
        .onChange(of: menuBarFormat) { _, _ in saveDisplay() }
    }

    private func makePlan() -> SessionPlan {
        SessionPlan(
            durationA: .seconds(UInt64(minutesA) * 60),
            durationB: .seconds(UInt64(minutesB) * 60),
            totalRounds: totalRounds
        )
    }

    private func makePreferences() -> DisplayPreferences {
        DisplayPreferences(
            menuBarLabelFormat: menuBarFormat,
            phaseLabels: PhaseLabels(nameA: nameA, nameB: nameB)
        )
    }

    private func savePlan() {
        guard isLoaded else { return }
        let plan = makePlan()
        Task {
            try? await settings.timer.save(plan)
            onSave(plan)
        }
    }

    private func saveDisplay() {
        guard isLoaded else { return }
        let prefs = makePreferences()
        Task {
            try? await settings.display.save(prefs)
            onDisplaySave(prefs)
        }
    }
}

private struct TimerTab: View {
    let plan: SessionPlan
    let settings: TimerSettings
    let onSave: (SessionPlan) -> Void
    @Binding var totalRounds: Int
    @Binding var nameA: String
    @Binding var nameB: String
    @Binding var minutesA: Int
    @Binding var minutesB: Int
    @Binding var selectedPart: Int

    var body: some View {
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
                        StartButton(plan: plan, onSave: onSave)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var totalDuration: Duration { plan.totalDuration }

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

private struct AppearanceTab: View {
    @Binding var menuBarFormat: MenuBarLabelFormat

    var body: some View {
        Form {
            Section {
                Picker("Menu bar", selection: $menuBarFormat) {
                    Text("Time").tag(MenuBarLabelFormat.time)
                    Text("Icon").tag(MenuBarLabelFormat.icon)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct StartButton: View {
    let plan: SessionPlan
    let onSave: (SessionPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(RuntimeProxy.self) private var timerRuntime

    var body: some View {
        Button {
            onSave(plan)
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
