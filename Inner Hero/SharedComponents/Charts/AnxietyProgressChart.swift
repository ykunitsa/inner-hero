import SwiftUI

struct AnxietyProgressChart: View {
    let anxietyBefore: Int
    let anxietyAfter: Int
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private enum Layout {
        static let headerSpacing: CGFloat = 12
        static let contentSpacing: CGFloat = 16
        static let barSpacing: CGFloat = 80
        static let barWidth: CGFloat = 50
        static let chartHeight: CGFloat = 200
        static let cardPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let barCornerRadius: CGFloat = 8
    }
    
    private var maxValue: CGFloat { 10 }
    
    private var beforeHeight: CGFloat {
        CGFloat(anxietyBefore) / maxValue
    }
    
    private var afterHeight: CGFloat {
        CGFloat(anxietyAfter) / maxValue
    }
    
    private var changeColor: Color {
        if anxietyAfter < anxietyBefore {
            return .green
        } else if anxietyAfter > anxietyBefore {
            return .red
        } else {
            return .orange
        }
    }
    
    private var changeIcon: String {
        if anxietyAfter < anxietyBefore {
            return "arrow.down"
        } else if anxietyAfter > anxietyBefore {
            return "arrow.up"
        } else {
            return "minus"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            Label("Динамика тревожности", systemImage: "chart.line.uptrend.xyaxis")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: Layout.contentSpacing) {
                GeometryReader { geometry in
                    let chartHeight = geometry.size.height
                    
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            ForEach(0..<11) { i in
                                Divider()
                                    .background(.separator)
                                if i < 10 {
                                    Spacer()
                                }
                            }
                        }
                        .accessibilityHidden(true)
                        
                        HStack(alignment: .bottom, spacing: Layout.barSpacing) {
                            BarView(
                                value: anxietyBefore,
                                height: chartHeight * beforeHeight,
                                maxHeight: chartHeight,
                                color: .blue,
                                label: "До"
                            )
                            
                            VStack {
                                Image(systemName: changeIcon)
                                    .font(.title)
                                    .foregroundStyle(changeColor)
                                    .padding(.bottom, chartHeight * 0.4)
                                    .accessibilityHidden(true)
                            }
                            
                            BarView(
                                value: anxietyAfter,
                                height: chartHeight * afterHeight,
                                maxHeight: chartHeight,
                                color: changeColor,
                                label: "После"
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: Layout.chartHeight)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("График динамики тревожности")
                
                HStack {
                    ScaleLabelView(value: "0", description: "Нет тревоги", alignment: .leading)
                    Spacer()
                    ScaleLabelView(value: "10", description: "Максимум", alignment: .trailing)
                }
                .accessibilityHidden(true)
            }
            .padding(Layout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .fill(.background.tertiary.opacity(0.5))
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Динамика тревожности от \(anxietyBefore) до \(anxietyAfter)")
    }
}

private struct BarView: View {
    let value: Int
    let height: CGFloat
    let maxHeight: CGFloat
    let color: Color
    let label: String
    
    private enum Layout {
        static let barWidth: CGFloat = 50
        static let barCornerRadius: CGFloat = 8
        static let spacing: CGFloat = 8
        static let labelSpacing: CGFloat = 4
    }
    
    var body: some View {
        VStack(spacing: Layout.spacing) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: Layout.barCornerRadius, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: Layout.barWidth, height: maxHeight)
                
                RoundedRectangle(cornerRadius: Layout.barCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: Layout.barWidth, height: height)
            }
            
            VStack(spacing: Layout.labelSpacing) {
                Text("\(value)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Scale Label View

private struct ScaleLabelView: View {
    let value: String
    let description: String
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(value)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
