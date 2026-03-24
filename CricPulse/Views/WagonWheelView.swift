import SwiftUI

// MARK: - Wagon Wheel

struct WagonWheelView: View {
    let shots: [WagonWheelShot]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wagon Wheel")
                .font(.headline.weight(.bold))

            if shots.isEmpty {
                Text("No shot data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Canvas { context, size in
                    let cx = size.width / 2
                    let cy = size.height / 2
                    let r  = min(cx, cy) - 14

                    // Outfield
                    let outerRect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    context.fill(
                        Path(ellipseIn: outerRect),
                        with: .color(Color(red: 0.05, green: 0.22, blue: 0.07))
                    )

                    // 30-yard circle (infield)
                    let ir = r * 0.55
                    let innerRect = CGRect(x: cx - ir, y: cy - ir, width: ir * 2, height: ir * 2)
                    context.fill(
                        Path(ellipseIn: innerRect),
                        with: .color(Color(red: 0.07, green: 0.28, blue: 0.09))
                    )

                    // Boundary ring
                    var boundary = Path()
                    boundary.addEllipse(in: outerRect)
                    context.stroke(boundary, with: .color(.white.opacity(0.35)), lineWidth: 1.5)

                    // 30-yard ring
                    var inner = Path()
                    inner.addEllipse(in: innerRect)
                    context.stroke(inner, with: .color(.white.opacity(0.18)), lineWidth: 1)

                    // Pitch rectangle
                    let pw = r * 0.07, ph = r * 0.30
                    context.fill(
                        Path(roundedRect: CGRect(x: cx - pw / 2, y: cy - ph / 2, width: pw, height: ph),
                             cornerSize: CGSize(width: 3, height: 3)),
                        with: .color(Color(red: 0.56, green: 0.43, blue: 0.22))
                    )

                    // Crease lines
                    context.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: cx - pw, y: cy - ph * 0.35))
                            p.addLine(to: CGPoint(x: cx + pw, y: cy - ph * 0.35))
                            p.move(to: CGPoint(x: cx - pw, y: cy + ph * 0.35))
                            p.addLine(to: CGPoint(x: cx + pw, y: cy + ph * 0.35))
                        },
                        with: .color(.white.opacity(0.5)),
                        lineWidth: 0.8
                    )

                    // Shot lines
                    let center = CGPoint(x: cx, y: cy)
                    for shot in shots {
                        let rad = shot.angle * .pi / 180.0
                        let dist = shot.distance * r
                        let ex = cx + dist * sin(rad)
                        let ey = cy - dist * cos(rad)
                        let end = CGPoint(x: ex, y: ey)
                        let color = shotColor(shot.runs)
                        let isBig = shot.runs >= 4

                        var line = Path()
                        line.move(to: center)
                        line.addLine(to: end)
                        context.stroke(line,
                                       with: .color(color.opacity(isBig ? 0.80 : 0.60)),
                                       lineWidth: isBig ? 1.8 : 1.2)

                        // Landing dot
                        let dr: CGFloat = isBig ? 3.5 : 2.5
                        context.fill(
                            Path(ellipseIn: CGRect(x: ex - dr, y: ey - dr, width: dr * 2, height: dr * 2)),
                            with: .color(color)
                        )
                    }
                }
                .frame(height: 290)
                .background(Color(red: 0.02, green: 0.10, blue: 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Legend
                HStack(spacing: 20) {
                    legendDot(.white.opacity(0.7),  "Singles / 2s / 3s")
                    legendDot(Color(hue: 0.6, saturation: 0.85, brightness: 1.0), "Fours")
                    legendDot(.red,                  "Sixes")
                }
            }
        }
        .padding(16)
        .background(CricColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CricColors.cardBorder, lineWidth: 1))
    }

    // MARK: - Helpers

    private func shotColor(_ runs: Int) -> Color {
        switch runs {
        case 6:     return .red
        case 4:     return Color(hue: 0.6, saturation: 0.85, brightness: 1.0)
        case 2, 3:  return Color(hue: 0.35, saturation: 0.8, brightness: 0.85)
        default:    return .white.opacity(0.7)
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
