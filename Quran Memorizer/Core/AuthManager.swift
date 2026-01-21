import Foundation
import SwiftUI
import AuthenticationServices
import Combine

/// Manages Sign in with Apple authentication
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userId: String?
    @Published private(set) var userEmail: String?
    @Published private(set) var userName: String?
    @Published private(set) var isLoading: Bool = false
    @Published var error: String?

    private let userIdKey = "appleUserId"
    private let userEmailKey = "appleUserEmail"
    private let userNameKey = "appleUserName"

    init() {
        loadSavedUser()
    }

    /// Check if previously signed in user is still valid
    func checkAuthStatus() {
        guard let userId = userId else {
            isSignedIn = false
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userId) { [weak self] state, error in
            Task { @MainActor [weak self] in
                switch state {
                case .authorized:
                    self?.isSignedIn = true
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }

    /// Handle Sign in with Apple result
    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = false

        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Save user info
                userId = credential.user
                UserDefaults.standard.set(credential.user, forKey: userIdKey)

                // Email and name are only provided on first sign in
                if let email = credential.email {
                    userEmail = email
                    UserDefaults.standard.set(email, forKey: userEmailKey)
                }

                if let fullName = credential.fullName {
                    let name = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    if !name.isEmpty {
                        userName = name
                        UserDefaults.standard.set(name, forKey: userNameKey)
                    }
                }

                isSignedIn = true
                error = nil

                // Trigger cloud sync after sign in
                Task {
                    await CloudSyncManager.shared.syncFromCloud()
                }
            }

        case .failure(let authError):
            if let authError = authError as? ASAuthorizationError,
               authError.code == .canceled {
                // User canceled, not an error
                error = nil
            } else {
                error = authError.localizedDescription
            }
            isSignedIn = false
        }
    }

    /// Sign out the current user
    func signOut() {
        userId = nil
        userEmail = nil
        userName = nil
        isSignedIn = false

        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
    }

    /// Delete account and all cloud data
    func deleteAccount() async {
        // Delete cloud data first
        await CloudSyncManager.shared.deleteAllCloudData()

        // Then sign out locally
        signOut()
    }

    private func loadSavedUser() {
        userId = UserDefaults.standard.string(forKey: userIdKey)
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        userName = UserDefaults.standard.string(forKey: userNameKey)

        if userId != nil {
            checkAuthStatus()
        }
    }
}
