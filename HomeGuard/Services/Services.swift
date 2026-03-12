import Foundation
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol PersistenceLayer {
    func saveTracking(_ data: [String: String])
    func loadAll() -> LoadedConfig
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func markFirstLaunchDone()
    func savePermissions(_ permissions: AppState.Config.PermissionData)
}

protocol Validator {
    func validate() async throws -> Bool
}

protocol Backend {
    func fetchAttribution(deviceID: String) async throws -> [String: Any]
    func fetchEndpoint(tracking: [String: Any]) async throws -> String
}

enum BackendError: Error { case invalidURL, requestFailed, decodingFailed }
