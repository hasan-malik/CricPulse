import SwiftUI

// MARK: - App Icon Manager

enum AppIconVariant: String, CaseIterable {
    case ball     = "AppIconBall"
    case ballDark = "AppIconBallDark"
    case bat      = "AppIconBat"
    case batDark  = "AppIconBatDark"

    var displayName: String {
        switch self {
        case .ball:     return "Red Ball"
        case .ballDark: return "Dark Ball"
        case .bat:      return "Cricket Bat"
        case .batDark:  return "Dark Bat"
        }
    }

    var emoji: String {
        switch self {
        case .ball, .ballDark: return "🏏"
        case .bat, .batDark:   return "🏏"
        }
    }

    /// Randomly picks either the ball or bat variant matching the current color scheme
    static func randomForLaunch(isDark: Bool) -> AppIconVariant {
        let options: [AppIconVariant] = isDark ? [.ballDark, .batDark] : [.ball, .bat]
        return options.randomElement() ?? .ball
    }
}

// MARK: - Icon Switching

@MainActor
func setAppIcon(_ variant: AppIconVariant) {
    #if os(iOS)
    guard UIApplication.shared.supportsAlternateIcons else { return }
    UIApplication.shared.setAlternateIconName(variant.rawValue) { error in
        if let error { print("Icon switch error: \(error)") }
    }
    #endif
}

@MainActor
func randomiseIconOnLaunch(isDark: Bool) {
    #if os(iOS)
    guard UIApplication.shared.supportsAlternateIcons else { return }
    let pick = AppIconVariant.randomForLaunch(isDark: isDark)
    UIApplication.shared.setAlternateIconName(pick.rawValue) { _ in }
    #endif
}

// MARK: - Icon Picker Sheet

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false

    let columns = [GridItem(.adaptive(minimum: 130), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AppIconVariant.allCases, id: \.self) { variant in
                        Button {
                            setAppIcon(variant)
                            dismiss()
                        } label: {
                            VStack(spacing: 10) {
                                // Preview tile
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(tileColor(variant))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Text(variant.emoji)
                                            .font(.system(size: 42))
                                    )
                                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                                Text(variant.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .trailingAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(CricColors.accent)
                }
            }
        }
    }

    private func tileColor(_ variant: AppIconVariant) -> Color {
        switch variant {
        case .ball:     return CricColors.accent
        case .ballDark: return Color(hex: "#0D0D16")
        case .bat:      return Color(hex: "#0A3A0E")
        case .batDark:  return Color(hex: "#12120A")
        }
    }
}
