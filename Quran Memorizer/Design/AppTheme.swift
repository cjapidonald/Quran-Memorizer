import SwiftUI
import Combine
import UIKit

enum ThemeStyle: String, CaseIterable {
    case dark
    case light

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
}
struct ReadingThemePalette {
    let backgroundGradient: LinearGradient
    let cardGradient: LinearGradient
    let borderColor: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let swatchGradient: LinearGradient
}

enum ReadingTheme: String, CaseIterable {
    case standard
    case sepia
    case sage
    case ocean
    case dusk
    case highContrast
    case midnight
    case aurora
    case deepSea

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .sepia: return "Sepia"
        case .sage: return "Sage"
        case .ocean: return "Ocean"
        case .dusk: return "Dusk"
        case .highContrast: return "High Contrast"
        case .midnight: return "Midnight"
        case .aurora: return "Aurora"
        case .deepSea: return "Deep Sea"
        }
    }

    static func defaultTheme(for colorScheme: ColorScheme) -> ReadingTheme {
        switch colorScheme {
        case .dark: return .midnight
        default: return .standard
        }
    }

    static func availableThemes(for colorScheme: ColorScheme) -> [ReadingTheme] {
        allCases.filter { $0.palette(for: colorScheme) != nil }
    }

    func palette(for colorScheme: ColorScheme) -> ReadingThemePalette? {
        switch (self, colorScheme) {
        case (.standard, .light):
            return .init(
                backgroundGradient: .solid(Color(.systemBackground)),
                cardGradient: .solid(Color(.secondarySystemBackground)),
                borderColor: Color(.separator),
                primaryTextColor: .primary,
                secondaryTextColor: .secondary,
                swatchGradient: .solid(Color(.secondarySystemBackground))
            )
        case (.standard, .dark):
            return .init(
                backgroundGradient: .solid(Color(.systemBackground)),
                cardGradient: .solid(Color(.secondarySystemBackground)),
                borderColor: Color(.separator),
                primaryTextColor: .white,
                secondaryTextColor: Color.white.opacity(0.7),
                swatchGradient: .solid(Color(.secondarySystemBackground))
            )
        case (.sepia, .light):
            return .init(
                backgroundGradient: .solid(Color(red: 0.98, green: 0.95, blue: 0.88)),
                cardGradient: .solid(Color(red: 0.99, green: 0.97, blue: 0.91)),
                borderColor: Color(red: 0.87, green: 0.78, blue: 0.64),
                primaryTextColor: .primary,
                secondaryTextColor: .secondary,
                swatchGradient: .solid(Color(red: 0.99, green: 0.97, blue: 0.91))
            )
        case (.sage, .light):
            return .init(
                backgroundGradient: .solid(Color(red: 0.93, green: 0.97, blue: 0.94)),
                cardGradient: .solid(Color(red: 0.96, green: 0.98, blue: 0.96)),
                borderColor: Color(red: 0.74, green: 0.85, blue: 0.74),
                primaryTextColor: .primary,
                secondaryTextColor: .secondary,
                swatchGradient: .solid(Color(red: 0.96, green: 0.98, blue: 0.96))
            )
        case (.ocean, .light):
            return .init(
                backgroundGradient: .solid(Color(red: 0.92, green: 0.96, blue: 0.99)),
                cardGradient: .solid(Color(red: 0.95, green: 0.98, blue: 1.0)),
                borderColor: Color(red: 0.64, green: 0.79, blue: 0.9),
                primaryTextColor: .primary,
                secondaryTextColor: .secondary,
                swatchGradient: .solid(Color(red: 0.95, green: 0.98, blue: 1.0))
            )
        case (.dusk, .light):
            return .init(
                backgroundGradient: .solid(Color(red: 0.95, green: 0.94, blue: 0.98)),
                cardGradient: .solid(Color(red: 0.98, green: 0.97, blue: 1.0)),
                borderColor: Color(red: 0.75, green: 0.7, blue: 0.87),
                primaryTextColor: .primary,
                secondaryTextColor: .secondary,
                swatchGradient: .solid(Color(red: 0.98, green: 0.97, blue: 1.0))
            )
        case (.dusk, .dark):
            return .init(
                backgroundGradient: LinearGradient(
                    colors: [Color(red: 0.18, green: 0.15, blue: 0.26), Color(red: 0.11, green: 0.09, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [Color(red: 0.24, green: 0.2, blue: 0.34), Color(red: 0.18, green: 0.15, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                borderColor: Color(red: 0.52, green: 0.46, blue: 0.7),
                primaryTextColor: .white,
                secondaryTextColor: Color.white.opacity(0.7),
                swatchGradient: LinearGradient(
                    colors: [Color(red: 0.4, green: 0.32, blue: 0.62), Color(red: 0.27, green: 0.22, blue: 0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case (.highContrast, .light):
            return .init(
                backgroundGradient: .solid(Color.white),
                cardGradient: .solid(Color.white),
                borderColor: Color.gray.opacity(0.4),
                primaryTextColor: .black,
                secondaryTextColor: Color(red: 0.28, green: 0.28, blue: 0.32),
                swatchGradient: .solid(Color.white)
            )
        case (.highContrast, .dark):
            return .init(
                backgroundGradient: .solid(Color.black),
                cardGradient: .solid(Color(red: 0.12, green: 0.12, blue: 0.12)),
                borderColor: Color.white.opacity(0.4),
                primaryTextColor: .white,
                secondaryTextColor: Color.white.opacity(0.7),
                swatchGradient: .solid(Color(red: 0.2, green: 0.2, blue: 0.2))
            )
        case (.midnight, .dark):
            return .init(
                backgroundGradient: LinearGradient(
                    colors: [Color(red: 0.07, green: 0.09, blue: 0.18), Color(red: 0.02, green: 0.04, blue: 0.11)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [Color(red: 0.13, green: 0.16, blue: 0.27), Color(red: 0.07, green: 0.09, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                borderColor: Color(red: 0.19, green: 0.27, blue: 0.42),
                primaryTextColor: .white,
                secondaryTextColor: Color.white.opacity(0.72),
                swatchGradient: LinearGradient(
                    colors: [Color(red: 0.24, green: 0.34, blue: 0.54), Color(red: 0.1, green: 0.16, blue: 0.28)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case (.aurora, .dark):
            return .init(
                backgroundGradient: LinearGradient(
                    colors: [Color(red: 0.09, green: 0.16, blue: 0.24), Color(red: 0.05, green: 0.1, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [Color(red: 0.16, green: 0.28, blue: 0.33), Color(red: 0.09, green: 0.16, blue: 0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                borderColor: Color(red: 0.26, green: 0.56, blue: 0.62),
                primaryTextColor: .white,
                secondaryTextColor: Color.white.opacity(0.72),
                swatchGradient: LinearGradient(
                    colors: [Color(red: 0.2, green: 0.62, blue: 0.6), Color(red: 0.35, green: 0.27, blue: 0.59)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case (.deepSea, .dark):
            return .init(
                backgroundGradient: LinearGradient(
                    colors: [Color(red: 0.02, green: 0.09, blue: 0.15), Color(red: 0.0, green: 0.02, blue: 0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [Color(red: 0.09, green: 0.18, blue: 0.26), Color(red: 0.02, green: 0.09, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                borderColor: Color(red: 0.0, green: 0.36, blue: 0.53),
                primaryTextColor: .white,
                secondaryTextColor: Color.white.opacity(0.72),
                swatchGradient: LinearGradient(
                    colors: [Color(red: 0.0, green: 0.53, blue: 0.68), Color(red: 0.0, green: 0.24, blue: 0.36)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        default:
            return nil
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("themeStyle") private var themeStyleRaw: String = ThemeStyle.dark.rawValue
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.standard.rawValue
    @AppStorage("glassIntensity") var glassIntensity: Double = 0.35

    var themeStyle: ThemeStyle {
        get { ThemeStyle(rawValue: themeStyleRaw) ?? .dark }
        set { themeStyleRaw = newValue.rawValue; objectWillChange.send() }
    }
    var readingTheme: ReadingTheme {
        get { ReadingTheme(rawValue: readingThemeRaw) ?? .standard }
        set { readingThemeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch themeStyle {
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension LinearGradient {
    static func solid(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct GlassBackground: View {
    var intensity: Double = 0.35
    var cornerRadius: CGFloat = 16
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(Color.white.opacity(intensity))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 0.7)
            )
    }
}

struct GradientProgressBar: View {
    var progress: Double
    var height: CGFloat = 10
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(LinearGradient(colors: [.green, .yellow, .green],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
        .animation(.easeInOut(duration: 0.25), value: progress)
    }
}

extension TimeInterval {
    var mmss: String {
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
