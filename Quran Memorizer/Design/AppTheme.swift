import SwiftUI
import Combine

enum ThemeStyle: String, CaseIterable { case system, light, dark }
enum ReadingTheme: String, CaseIterable { case standard, sepia, highContrast }

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
