import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var prefs: AppPrefsStore
    @State private var showShare = false
    @State private var showDelete = false
    @State private var showSignin = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { theme.themeStyle },
                        set: { theme.themeStyle = $0 }
                    )) {
                        Text("System").tag(ThemeStyle.system)
                        Text("Light").tag(ThemeStyle.light)
                        Text("Dark").tag(ThemeStyle.dark)
                    }
                    Picker("Reading theme", selection: Binding(
                        get: { theme.readingTheme },
                        set: { theme.readingTheme = $0 }
                    )) {
                        ForEach(ReadingTheme.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    HStack {
                        Text("Glass intensity")
                        Slider(value: $theme.glassIntensity, in: 0...0.6)
                    }
                }

                Section("Audio") {
                    Picker("Default reciter", selection: Binding(
                        get: { prefs.defaultReciter },
                        set: { prefs.defaultReciter = $0 }
                    )) {
                        ForEach(Reciter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
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
                ShareSheet(activityItems: ["Check out Quran Memorizer — a simple app for hifdh with A↔B loop playback."])
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
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
