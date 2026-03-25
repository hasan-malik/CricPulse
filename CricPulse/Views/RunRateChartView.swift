import SwiftUI
import Charts

struct RunRateChartView: View {
    let data: [OverData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Run Rate")
                .font(.headline.weight(.bold))

            if data.isEmpty {
                Text("No over data available")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Over", point.over),
                        y: .value("Runs", point.runs)
                    )
                    .foregroundStyle(barColor(point.runs))
                    .cornerRadius(3)

                    // Red vertical line on wicket overs
                    if point.wickets > 0 {
                        RuleMark(x: .value("Over", point.over))
                            .foregroundStyle(CricColors.accent.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .annotation(position: .top, alignment: .center) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundStyle(CricColors.accent)
                            }
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) {
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel().foregroundStyle(.secondary).font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks {
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel().foregroundStyle(.secondary).font(.caption2)
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    legendItem(CricColors.accent.opacity(0.55), "0–9 runs")
                    legendItem(CricColors.t20,                  "10–14 runs")
                    legendItem(CricColors.odi,                  "15+ runs")
                    Spacer()
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(CricColors.accent.opacity(0.5))
                            .frame(width: 10, height: 1.5)
                        Text("Wicket").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }

    private func barColor(_ runs: Int) -> Color {
        if runs >= 15 { return CricColors.odi }
        if runs >= 10 { return CricColors.t20 }
        return CricColors.accent.opacity(0.55 + Double(runs) * 0.035)
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
