import SwiftUI
import GrainDomain

struct SettingsView: View {
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var draft = PlanDraft()

    var body: some View {
        List {
            NavigationLink {
                ValuePicker(title: "Phase A", range: 1...90, unit: "min", amount: $draft.minutesA)
            } label: {
                SettingRow(title: "Phase A", value: "\(draft.minutesA) min")
            }
            NavigationLink {
                ValuePicker(title: "Phase B", range: 1...90, unit: "min", amount: $draft.minutesB)
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
    var minutesA = 50
    var minutesB = 15

    init() {}

    init(from plan: SessionPlan) {
        minutesA = max(1, Int((plan.intervals.first { $0.tag == .a }?.duration.seconds ?? 3000) / 60))
        minutesB = max(1, Int((plan.intervals.first { $0.tag == .b }?.duration.seconds ?? 900) / 60))
    }

    var plan: SessionPlan {
        SessionPlan(intervals: [
            Interval(tag: .a, duration: .seconds(UInt64(minutesA) * 60)),
            Interval(tag: .b, duration: .seconds(UInt64(minutesB) * 60))
        ])
    }
}
