import Foundation
import Combine

final class DiskPersistence: PersistenceLayer {
    private let store = UserDefaults(suiteName: "group.home.guard")!
    private let cache = UserDefaults.standard
    private var memory: [String: Any] = [:]
    
    private enum Key {
        static let tracking = "hg_tracking_payload"
        static let navigation = "hg_navigation_payload"
        static let endpoint = "hg_endpoint_target"
        static let mode = "hg_mode_active"
        static let firstLaunch = "hg_first_launch_flag"
        static let permApproved = "hg_perm_approved"
        static let permDeclined = "hg_perm_declined"
        static let permDate = "hg_perm_date"
    }
    
    init() { preload() }
    
    func saveTracking(_ data: [String: String]) {
        if let json = toJSON(data) {
            store.set(json, forKey: Key.tracking)
            memory[Key.tracking] = json
        }
    }
    
    func saveNavigation(_ data: [String: String]) {
        if let json = toJSON(data) {
            let encoded = encode(json)
            store.set(encoded, forKey: Key.navigation)
        }
    }
    
    func saveEndpoint(_ url: String) {
        store.set(url, forKey: Key.endpoint)
        cache.set(url, forKey: Key.endpoint)
        memory[Key.endpoint] = url
    }
    
    func saveMode(_ mode: String) { store.set(mode, forKey: Key.mode) }
    func markFirstLaunchDone() { store.set(true, forKey: Key.firstLaunch) }
    
    func savePermissions(_ permissions: AppState.Config.PermissionData) {
        store.set(permissions.approved, forKey: Key.permApproved)
        store.set(permissions.declined, forKey: Key.permDeclined)
        if let date = permissions.lastAsked {
            store.set(date.timeIntervalSince1970 * 1000, forKey: Key.permDate)
        }
    }
    
    func loadAll() -> LoadedConfig {
        let mode = store.string(forKey: Key.mode)
        let isFirstLaunch = !store.bool(forKey: Key.firstLaunch)
        
        var tracking: [String: String] = [:]
        if let json = memory[Key.tracking] as? String ?? store.string(forKey: Key.tracking),
           let dict = fromJSON(json) { tracking = dict }
        
        var navigation: [String: String] = [:]
        if let encoded = store.string(forKey: Key.navigation),
           let json = decode(encoded),
           let dict = fromJSON(json) { navigation = dict }
        
        let approved = store.bool(forKey: Key.permApproved)
        let declined = store.bool(forKey: Key.permDeclined)
        let ts = store.double(forKey: Key.permDate)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return LoadedConfig(
            mode: mode,
            isFirstLaunch: isFirstLaunch,
            tracking: tracking,
            navigation: navigation,
            permissions: LoadedConfig.PermissionData(approved: approved, declined: declined, lastAsked: date)
        )
    }
    
    private func preload() {
        if let endpoint = store.string(forKey: Key.endpoint) { memory[Key.endpoint] = endpoint }
    }
    
    private func toJSON(_ dict: [String: String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict.mapValues { $0 as Any }),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dict.mapValues { "\($0)" }
    }
    
    private func encode(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: ":")
            .replacingOccurrences(of: "+", with: ";")
    }
    
    private func decode(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: ":", with: "=")
            .replacingOccurrences(of: ";", with: "+")
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}
