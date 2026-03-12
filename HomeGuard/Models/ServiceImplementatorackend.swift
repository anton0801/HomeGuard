import AppsFlyerLib
import Firebase
import WebKit
import FirebaseMessaging

final class HTTPBackend: Backend {
    private let client: URLSession
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    

    
    func fetchAttribution(deviceID: String) async throws -> [String: Any] {
        var builder = URLComponents(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(HomeConfig.appID)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: HomeConfig.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        guard let url = builder?.url else { throw BackendError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await client.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else { throw BackendError.requestFailed }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw BackendError.decodingFailed }
        return json
    }
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.client = URLSession(configuration: config)
    }
    
    func fetchEndpoint(tracking: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://homeguarrd.com/config.php") else { throw BackendError.invalidURL }
        
        var payload: [String: Any] = tracking
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(HomeConfig.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [17.0, 34.0, 68.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await client.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw BackendError.requestFailed }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool, success,
                          let endpoint = json["url"] as? String else { throw BackendError.decodingFailed }
                    return endpoint
                } else if httpResponse.statusCode == 429 {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(index + 1) * 1_000_000_000))
                    continue
                } else {
                    throw BackendError.requestFailed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError ?? BackendError.requestFailed
    }
}
