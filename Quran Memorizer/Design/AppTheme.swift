import SwiftUI
import Combine
import UIKit

enum ThemeStyle: String, CaseIterable { case system, light, dark }
extension ThemeStyle {
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
enum ReadingTheme: String, CaseIterable {
    case standard
    case sepia
    case sage
    case ocean
    case dusk
    case highContrast

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .sepia: return "Sepia"
        case .sage: return "Sage"
        case .ocean: return "Ocean"
        case .dusk: return "Dusk"
        case .highContrast: return "High Contrast"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .standard: return Color(.systemBackground)
        case .sepia: return Color(red: 0.98, green: 0.95, blue: 0.88)
        case .sage: return Color(red: 0.93, green: 0.97, blue: 0.94)
        case .ocean: return Color(red: 0.92, green: 0.96, blue: 0.99)
        case .dusk: return Color(red: 0.95, green: 0.94, blue: 0.98)
        case .highContrast: return Color.white
        }
    }

    var cardColor: Color {
        switch self {
        case .standard: return Color(.secondarySystemBackground)
        case .sepia: return Color(red: 0.99, green: 0.97, blue: 0.91)
        case .sage: return Color(red: 0.96, green: 0.98, blue: 0.96)
        case .ocean: return Color(red: 0.95, green: 0.98, blue: 1.0)
        case .dusk: return Color(red: 0.98, green: 0.97, blue: 1.0)
        case .highContrast: return Color.white
        }
    }

    var borderColor: Color {
        switch self {
        case .standard: return Color(.separator)
        case .sepia: return Color(red: 0.87, green: 0.78, blue: 0.64)
        case .sage: return Color(red: 0.74, green: 0.85, blue: 0.74)
        case .ocean: return Color(red: 0.64, green: 0.79, blue: 0.9)
        case .dusk: return Color(red: 0.75, green: 0.7, blue: 0.87)
        case .highContrast: return Color.gray.opacity(0.4)
        }
    }

    var swatchColor: Color { cardColor }

    var primaryTextColor: Color {
        switch self {
        case .highContrast: return .black
        default: return .primary
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .highContrast: return Color(red: 0.28, green: 0.28, blue: 0.32)
        default: return .secondary
        }
    }
}

final class ThemeManager: ObservableObject {
    @AppStorage("themeStyle") private var themeStyleRaw: String = ThemeStyle.system.rawValue
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.standard.rawValue
    @AppStorage("glassIntensity") var glassIntensity: Double = 0.35

    var themeStyle: ThemeStyle {
        get { ThemeStyle(rawValue: themeStyleRaw) ?? .system }
        set { themeStyleRaw = newValue.rawValue; objectWillChange.send() }
    }
    var readingTheme: ReadingTheme {
        get { ReadingTheme(rawValue: readingThemeRaw) ?? .standard }
        set { readingThemeRaw = newValue.rawValue; objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch themeStyle {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
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
