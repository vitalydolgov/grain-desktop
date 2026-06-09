import SwiftUI
import GrainDomain

public struct IntervalDots: View {
    let count: Int
    let currentIndex: Int
    let status: SessionStatus
    let color: Color
    var inactiveColor: Color?

    public init(count: Int, currentIndex: Int, status: SessionStatus, color: Color, inactiveColor: Color? = nil) {
        self.count = count
        self.currentIndex = currentIndex
        self.status = status
        self.color = color
        self.inactiveColor = inactiveColor
    }

    public var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == effectiveIndex ? color : inactive)
                    .frame(width: 8, height: 8)
                    .shadow(color: index == effectiveIndex ? color.opacity(0.5) : .clear,
                            radius: 2.5, x: 0, y: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: effectiveIndex)
            }
        }
        .opacity(count == 1 ? 0 : 1)
    }

    private var effectiveIndex: Int {
        status == .idle || status == .completed ? -1 : currentIndex
    }

    private var inactive: Color {
        inactiveColor ?? color.opacity(0.22)
    }
}
