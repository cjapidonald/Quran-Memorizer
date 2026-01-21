import Foundation
import CloudKit
import Combine

/// Manages CloudKit sync for user progress data
@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncDate: Date?
    @Published var syncError: String?

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // Record types
    private let highlightsRecordType = "SurahHighlights"
    private let memorizedAyahsRecordType = "MemorizedAyahs"
    private let preferencesRecordType = "UserPreferences"

    // Record IDs (one record per user for each type)
    private let highlightsRecordName = "userHighlights"
    private let memorizedAyahsRecordName = "userMemorizedAyahs"
    private let preferencesRecordName = "userPreferences"

    init() {
        // Use the default container or specify your container ID
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Sync Operations

    /// Sync all data to CloudKit
    func syncToCloud() async {
        guard AuthManager.shared.isSignedIn else { return }

        isSyncing = true
        syncError = nil

        do {
            // Sync highlights
            try await syncHighlightsToCloud()

            // Sync memorized ayahs
            try await syncMemorizedAyahsToCloud()

            // Sync preferences
            try await syncPreferencesToCloud()

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")

        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Fetch all data from CloudKit
    func syncFromCloud() async {
        guard AuthManager.shared.isSignedIn else { return }

        isSyncing = true
        syncError = nil

        do {
            // Fetch highlights
            try await fetchHighlightsFromCloud()

            // Fetch memorized ayahs
            try await fetchMemorizedAyahsFromCloud()

            // Fetch preferences
            try await fetchPreferencesFromCloud()

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastCloudSyncDate")

        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                // No data in cloud yet, that's okay
                syncError = nil
            } else {
                syncError = "Fetch failed: \(error.localizedDescription)"
            }
        }

        isSyncing = false
    }

    /// Delete all cloud data (for account deletion)
    func deleteAllCloudData() async {
        do {
            let recordIDs = [
                CKRecord.ID(recordName: highlightsRecordName),
                CKRecord.ID(recordName: memorizedAyahsRecordName),
                CKRecord.ID(recordName: preferencesRecordName)
            ]

            for recordID in recordIDs {
                _ = try? await privateDatabase.deleteRecord(withID: recordID)
            }
        }
    }

    // MARK: - Highlights Sync

    private func syncHighlightsToCloud() async throws {
        let highlights = HighlightStore.shared.highlights

        // Convert to JSON-compatible format
        let data: [String: String] = highlights.reduce(into: [:]) { result, item in
            result[String(item.key)] = item.value.rawValue
        }

        let recordID = CKRecord.ID(recordName: highlightsRecordName)

        // Try to fetch existing record or create new one
        let record: CKRecord
        do {
            record = try await privateDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: highlightsRecordType, recordID: recordID)
        }

        // Encode data as JSON
        if let jsonData = try? JSONEncoder().encode(data) {
            record["data"] = String(data: jsonData, encoding: .utf8)
            record["lastModified"] = Date()
        }

        try await privateDatabase.save(record)
    }

    private func fetchHighlightsFromCloud() async throws {
        let recordID = CKRecord.ID(recordName: highlightsRecordName)
        let record = try await privateDatabase.record(for: recordID)

        if let jsonString = record["data"] as? String,
           let jsonData = jsonString.data(using: .utf8),
           let data = try? JSONDecoder().decode([String: String].self, from: jsonData) {

            // Convert back to [Int: HighlightState]
            var highlights: [Int: HighlightState] = [:]
            for (key, value) in data {
                if let id = Int(key), let state = HighlightState(rawValue: value) {
                    highlights[id] = state
                }
            }

            // Update local store
            HighlightStore.shared.replaceAll(highlights)
        }
    }

    // MARK: - Memorized Ayahs Sync

    private func syncMemorizedAyahsToCloud() async throws {
        let memorized = MemorizedAyahStore.shared.memorized

        // Convert Set<Int> to [Int] for JSON encoding
        let data: [String: [Int]] = memorized.reduce(into: [:]) { result, item in
            result[String(item.key)] = Array(item.value).sorted()
        }

        let recordID = CKRecord.ID(recordName: memorizedAyahsRecordName)

        let record: CKRecord
        do {
            record = try await privateDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: memorizedAyahsRecordType, recordID: recordID)
        }

        if let jsonData = try? JSONEncoder().encode(data) {
            record["data"] = String(data: jsonData, encoding: .utf8)
            record["lastModified"] = Date()
        }

        try await privateDatabase.save(record)
    }

    private func fetchMemorizedAyahsFromCloud() async throws {
        let recordID = CKRecord.ID(recordName: memorizedAyahsRecordName)
        let record = try await privateDatabase.record(for: recordID)

        if let jsonString = record["data"] as? String,
           let jsonData = jsonString.data(using: .utf8),
           let data = try? JSONDecoder().decode([String: [Int]].self, from: jsonData) {

            // Convert back to [Int: Set<Int>]
            var memorized: [Int: Set<Int>] = [:]
            for (key, value) in data {
                if let id = Int(key) {
                    memorized[id] = Set(value)
                }
            }

            // Update local store
            MemorizedAyahStore.shared.replaceAll(memorized)
        }
    }

    // MARK: - Preferences Sync

    private func syncPreferencesToCloud() async throws {
        let prefs = AppPrefsStore.shared
        let recordID = CKRecord.ID(recordName: preferencesRecordName)

        let record: CKRecord
        do {
            record = try await privateDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: preferencesRecordType, recordID: recordID)
        }

        record["selectedQariId"] = prefs.selectedQariId
        record["selectedQariPath"] = prefs.selectedQariPath
        record["selectedQariName"] = prefs.selectedQariName
        record["lastModified"] = Date()

        try await privateDatabase.save(record)
    }

    private func fetchPreferencesFromCloud() async throws {
        let recordID = CKRecord.ID(recordName: preferencesRecordName)
        let record = try await privateDatabase.record(for: recordID)

        let prefs = AppPrefsStore.shared

        if let qariId = record["selectedQariId"] as? Int {
            prefs.selectedQariId = qariId
        }
        if let qariPath = record["selectedQariPath"] as? String {
            prefs.selectedQariPath = qariPath
        }
        if let qariName = record["selectedQariName"] as? String {
            prefs.selectedQariName = qariName
        }
    }
}
