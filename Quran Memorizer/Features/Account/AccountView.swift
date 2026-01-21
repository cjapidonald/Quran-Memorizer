import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var cloudSync: CloudSyncManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                if authManager.isSignedIn {
                    signedInContent
                } else {
                    signedOutContent
                }
            }
            .navigationTitle("Account")
            .alert("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Your progress is saved locally and in iCloud. You can sign back in anytime to sync across devices.")
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await authManager.deleteAccount()
                    }
                }
            } message: {
                Text("This will delete all your cloud data. Local progress on this device will be kept.")
            }
        }
    }

    // MARK: - Signed Out Content

    @ViewBuilder
    private var signedOutContent: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "icloud")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                Text("Sign in to sync your progress")
                    .font(.headline)

                Text("Your memorization progress will be backed up to iCloud and synced across all your devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }

        Section {
            SignInWithAppleButtonView()
                .frame(height: 50)
        }

        Section {
            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "icloud.fill", title: "iCloud Backup", description: "Never lose your progress")
                benefitRow(icon: "arrow.triangle.2.circlepath", title: "Sync Across Devices", description: "iPhone, iPad, and more")
                benefitRow(icon: "lock.shield.fill", title: "Private & Secure", description: "Only you can access your data")
            }
            .padding(.vertical, 8)
        } header: {
            Text("Benefits")
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Signed In Content

    @ViewBuilder
    private var signedInContent: some View {
        Section {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    if let name = authManager.userName, !name.isEmpty {
                        Text(name)
                            .font(.headline)
                    }
                    if let email = authManager.userEmail {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("Signed in with Apple")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 8)
        }

        Section {
            HStack {
                Label("iCloud Sync", systemImage: "icloud.fill")
                Spacer()
                if cloudSync.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let lastSync = cloudSync.lastSyncDate {
                HStack {
                    Label("Last Synced", systemImage: "clock")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    await cloudSync.syncToCloud()
                }
            } label: {
                Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(cloudSync.isSyncing)

            if let error = cloudSync.syncError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Sync Status")
        }

        Section {
            Button {
                showSignOutConfirm = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Account & Cloud Data", systemImage: "trash")
            }
        }
    }
}

// MARK: - Sign In Button

struct SignInWithAppleButtonView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                authManager.handleSignInResult(result)
            }
        )
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .cornerRadius(10)
    }
}

#Preview("Signed Out") {
    AccountView()
        .environmentObject(AuthManager.shared)
        .environmentObject(CloudSyncManager.shared)
}
