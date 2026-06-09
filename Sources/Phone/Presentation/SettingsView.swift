import SwiftUI
import GrainDomain
import GrainApplication

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppSettings.self) private var settings
    @Environment(RuntimeProxy.self) private var timerRuntime
    @State private var configuration = PlanConfiguration.default

    private var theme: PhaseTheme {
        .idle(colorScheme)
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Header(theme: theme, onDone: { dismiss() })

                TotalCard(theme: theme,
                          range: 40...240,
                          step: 5,
                          minutes: $configuration.totalMinutes)

                SkipBreakCard(theme: theme, enabled: canToggleEndMode, skip: Binding(
                    get: { !configuration.endWithB },
                    set: { configuration.endWithB = !$0 }
                ))

                if let plan = configuration.makePlan() {
                    PlanPreviewCard(plan: plan, theme: theme)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
        }
        .onChange(of: settings.configuration, initial: true) {
            configuration = settings.configuration
        }
        .onChange(of: configuration) {
            if configuration.isFeasible {
                saveConfiguration(configuration)
            } else if let alternative = feasibleAlternative(for: configuration) {
                configuration = alternative
            }
        }
    }

    private var canToggleEndMode: Bool {
        configuration.canPlan(endWithB: true) && configuration.canPlan(endWithB: false)
    }

    private func feasibleAlternative(for configuration: PlanConfiguration) -> PlanConfiguration? {
        let alternative = PlanConfiguration(totalMinutes: configuration.totalMinutes, endWithB: !configuration.endWithB)
        return alternative.isFeasible ? alternative : nil
    }

    private func saveConfiguration(_ configuration: PlanConfiguration) {
        guard configuration != settings.configuration else { return }
        if let plan = configuration.makePlan() {
            timerRuntime.setPlan(plan)
        }
        settings.configuration = configuration
        Task { await settings.save() }
    }
}

private struct Header: View {
    let theme: PhaseTheme
    let onDone: () -> Void

    var body: some View {
        HStack {
            Text("Plan")
                .textCase(.uppercase)
                .font(.customRegular(size: 17))
                .tracking(5)
                .foregroundStyle(theme.labelColor)

            Spacer()

            Button(action: onDone) {
                Circle()
                    .fill(theme.controlSurfaceColor)
                    .frame(width: 38, height: 38)
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(theme.controlIconColor)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct TotalCard: View {
    let theme: PhaseTheme
    let range: ClosedRange<Int>
    let step: Int
    @Binding var minutes: Int

    var body: some View {
        Card(theme: theme) {
            VStack(spacing: 18) {
                Text("Total")
                    .textCase(.uppercase)
                    .font(.customRegular(size: 12))
                    .tracking(3)
                    .foregroundStyle(theme.labelColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    StepButton(icon: "minus", theme: theme,
                               enabled: minutes > range.lowerBound,
                               action: { adjust(by: -step) })

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(minutes)")
                            .font(.customMonospaced(size: 52))
                            .foregroundStyle(theme.timerTextColor)
                            .contentTransition(.numericText())
                        Text("min")
                            .font(.customRegular(size: 16))
                            .foregroundStyle(theme.labelColor)
                    }

                    Spacer()

                    StepButton(icon: "plus", theme: theme,
                               enabled: minutes < range.upperBound,
                               action: { adjust(by: step) })
                }
            }
        }
    }

    private func adjust(by delta: Int) {
        let next = (minutes + delta).clamped(to: range)
        withAnimation(.snappy(duration: 0.2)) { minutes = next }
    }
}

private struct StepButton: View {
    let icon: String
    let theme: PhaseTheme
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(theme.accentColor)
                .frame(width: 52, height: 52)
                .shadow(color: theme.accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(theme.onAccentColor)
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }
}

private struct SkipBreakCard: View {
    let theme: PhaseTheme
    let enabled: Bool
    @Binding var skip: Bool

    var body: some View {
        Card(theme: theme) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Skip final break")
                        .font(.customRegular(size: 17))
                        .foregroundStyle(theme.timerTextColor)
                    Spacer()
                    PillToggle(theme: theme, isOn: $skip)
                        .disabled(!enabled)
                        .opacity(enabled ? 1 : 0.4)
                }
                if !enabled {
                    VStack(alignment: .leading, spacing: 2) {
                        if skip {
                            Text("No optimal split with final break")
                        } else {
                            Text("No optimal split without final break")
                        }
                    }
                    .font(.customRegular(size: 13))
                    .foregroundStyle(theme.labelColor)
                }
            }
        }
    }
}

private struct PillToggle: View {
    let theme: PhaseTheme
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isOn.toggle() }
        } label: {
            Capsule()
                .fill(isOn ? theme.accentColor : theme.controlIconColor.opacity(0.25))
                .frame(width: 52, height: 31)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 25, height: 25)
                        .padding(3)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct PlanPreviewCard: View {
    let plan: SessionPlan
    let theme: PhaseTheme

    var body: some View {
        Card(theme: theme) {
            VStack(spacing: 14) {
                SplitBar(intervals: plan.intervals)
                    .font(.customMonospaced(size: 11))
                    .frame(height: 26)
                    .transaction { $0.animation = nil }
                SplitBarLegend(spacing: 12, dotSize: 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transaction { $0.animation = nil }
            }
        }
    }
}

private struct Card<Content: View>: View {
    let theme: PhaseTheme
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.controlSurfaceColor)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
