import SwiftUI

struct IntervalDots: View {
    let count: Int
    let currentIndex: Int
    let color: Color
    var inactiveColor: Color? = nil

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? color : inactive)
                    .frame(width: 8, height: 8)
                    .shadow(color: index == currentIndex ? color.opacity(0.5) : .clear,
                            radius: 2.5, x: 0, y: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }

    private var inactive: Color {
        inactiveColor ?? color.opacity(0.22)
    }
}
