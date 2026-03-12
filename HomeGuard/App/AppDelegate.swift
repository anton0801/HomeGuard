import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private let attributionBridge = AttributionBridge()
    private let pushBridge = PushBridge()
    private var sdkBridge: SDKBridge?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        attributionBridge.onTracking = { [weak self] in self?.relay(tracking: $0) }
        attributionBridge.onNavigation = { [weak self] in self?.relay(navigation: $0) }
        sdkBridge = SDKBridge(bridge: attributionBridge)
        
        setupFirebase()
        setupPush()
        setupSDK()
        
        if let push = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushBridge.process(push)
        }
        
        observeLifecycle()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func setupFirebase() { FirebaseApp.configure() }
    
    private func setupPush() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func setupSDK() { sdkBridge?.configure() }
    
    private func observeLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(activate), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func activate() { sdkBridge?.start() }
    
    private func relay(tracking data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
    }
    
    private func relay(navigation data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.home.storage")?.set(token, forKey: "shared_fcm")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushBridge.process(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushBridge.process(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        pushBridge.process(userInfo)
        completionHandler(.newData)
    }
}

final class AttributionBridge: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    
    private var trackingBuf: [AnyHashable: Any] = [:]
    private var navigationBuf: [AnyHashable: Any] = [:]
    private var timer: Timer?
    
    func receiveTracking(_ data: [AnyHashable: Any]) {
        trackingBuf = data
        scheduleTimer()
        if !navigationBuf.isEmpty { merge() }
    }
    
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "hg_first_launch_flag") else { return }
        navigationBuf = data
        onNavigation?(data)
        timer?.invalidate()
        if !trackingBuf.isEmpty { merge() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() }
    }
    
    private func merge() {
        var result = trackingBuf
        navigationBuf.forEach { k, v in
            let key = "deep_\(k)"
            if result[key] == nil { result[key] = v }
        }
        onTracking?(result)
    }
}
