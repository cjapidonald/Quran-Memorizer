import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var prefs: AppPrefsStore
    @State private var showShare = false
    @State private var showDelete = false
    @State private var showSignin = false
    private let optionColumns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: optionColumns, spacing: 12) {
                            ForEach(ThemeStyle.allCases, id: \.self) { style in
                                Button {
                                    theme.themeStyle = style
                                } label: {
                                    selectionButton(title: style.displayName, isSelected: theme.themeStyle == style)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reading theme")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: optionColumns, spacing: 12) {
                            ForEach(ReadingTheme.allCases, id: \.self) { option in
                                Button {
                                    theme.readingTheme = option
                                } label: {
                                    selectionButton(title: option.displayName, isSelected: theme.readingTheme == option, swatch: option.swatchColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack {
                        Text("Glass intensity")
                        Slider(value: $theme.glassIntensity, in: 0...0.6)
                    }
                }

                Section("Audio") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Default reciter")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: optionColumns, spacing: 12) {
                            ForEach(Reciter.allCases, id: \.self) { reciter in
                                Button {
                                    prefs.defaultReciter = reciter
                                } label: {
                                    selectionButton(title: reciter.rawValue, isSelected: prefs.defaultReciter == reciter)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("Account") {
                    Button("Sign in with Apple (coming soon)") { showSignin = true }
                    Button("Delete account (coming soon)", role: .destructive) { showDelete = true }
                }

                Section("About") {
                    Text("Quran Memorizer\nDeveloper: Donald Cjapi (2025)")
                    Button("Share this app") { showShare = true }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showShare) {
                ShareSheet(activityItems: ["Check out Quran Memorizer — a simple app for hifz with A↔B loop playback."])
            }
            .alert("Sign-in", isPresented: $showSignin) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Sign in will be added later.")
            }
            .alert("Delete account", isPresented: $showDelete) {
                Button("Cancel", role: .cancel) { }
                Button("OK", role: .destructive) { }
            } message: {
                Text("This will be implemented with CloudKit later.")
            }
        }
    }

    @ViewBuilder
    private func selectionButton(title: String, isSelected: Bool, swatch: Color? = nil) -> some View {
        HStack(spacing: 10) {
            if let swatch {
                Circle()
                    .fill(swatch)
                    .frame(width: 18, height: 18)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
