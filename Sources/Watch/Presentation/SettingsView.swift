import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var draft = PlanDraft()

    var body: some View {
        List {
            NavigationLink {
                ValuePicker(title: "Rounds", range: 1...6, unit: nil, amount: $draft.rounds)
            } label: {
                SettingRow(title: "Rounds", value: "\(draft.rounds)")
            }
            NavigationLink {
                ValuePicker(title: "Phase A", range: 1...60, unit: "min", amount: $draft.minutesA)
            } label: {
                SettingRow(title: "Phase A", value: "\(draft.minutesA) min")
            }
            NavigationLink {
                ValuePicker(title: "Phase B", range: 1...60, unit: "min", amount: $draft.minutesB)
            } label: {
                SettingRow(title: "Phase B", value: "\(draft.minutesB) min")
            }
        }
        .navigationTitle("Timer")
        .onAppear { draft = PlanDraft(from: timerRuntime.plan) }
        .onChange(of: draft) { timerRuntime.setPlan(draft.plan) }
    }
}

private struct SettingRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ValuePicker: View {
    let title: String
    let range: ClosedRange<Int>
    let unit: String?
    @Binding var amount: Int

    var body: some View {
        Picker(title, selection: $amount) {
            ForEach(Array(range), id: \.self) { value in
                Text(label(for: value)).tag(value)
            }
        }
        .pickerStyle(.wheel)
        .navigationTitle(title)
    }

    private func label(for value: Int) -> String {
        guard let unit else { return "\(value)" }
        return "\(value) \(unit)"
    }
}

private struct PlanDraft: Equatable {
    var rounds = SessionPlan.default.totalCycles
    var minutesA = Int(SessionPlan.default.durationA.seconds / 60)
    var minutesB = Int(SessionPlan.default.durationB.seconds / 60)

    init() {}

    init(from plan: SessionPlan) {
        rounds = plan.totalCycles
        minutesA = max(1, Int(plan.durationA.seconds / 60))
        minutesB = max(1, Int(plan.durationB.seconds / 60))
    }

    var plan: SessionPlan {
        SessionPlan(
            durationA: .seconds(UInt64(minutesA) * 60),
            durationB: .seconds(UInt64(minutesB) * 60),
            totalCycles: rounds
        )
    }
}
