import SwiftUI

struct SegmentedProgressView: View {
    let percent: Double
    var segmentCount = 7
    var barHeight: CGFloat = 10
    var tint: Color?
    var progressLabel = "周额度已使用"

    private var normalizedProgress: Double {
        min(max(percent, 0), 100) / 100
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<segmentCount, id: \.self) { index in
                GeometryReader { geometry in
                    let fill = min(max(normalizedProgress * Double(segmentCount) - Double(index), 0), 1)
                    ZStack(alignment: .leading) {
                        Capsule().fill(.quaternary)
                        Capsule()
                            .fill(tint ?? progressColor)
                            .frame(width: geometry.size.width * fill)
                    }
                }
            }
        }
        .frame(height: barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(progressLabel)
        .accessibilityValue("\((normalizedProgress * 100).formatted(.number.precision(.fractionLength(2))))%")
    }

    private var progressColor: Color {
        switch percent {
        case 85...: .red
        case 65...: .orange
        default: .accentColor
        }
    }
}

struct ContinuousProgressView: View {
    let percent: Int

    var body: some View {
        ProgressView(value: Double(min(max(percent, 0), 100)), total: 100)
            .tint(percent >= 85 ? .red : percent >= 65 ? .orange : .accentColor)
            .accessibilityLabel("额度已使用 \(percent)%")
    }
}
