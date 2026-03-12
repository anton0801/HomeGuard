import Foundation
import AppsFlyerLib
import AppTrackingTransparency

final class SDKBridge: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private var bridge: AttributionBridge
    
    init(bridge: AttributionBridge) { self.bridge = bridge }
    
    func configure() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = HomeConfig.devKey
        sdk.appleAppID = HomeConfig.appID
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func start() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) { bridge.receiveTracking(data) }
    func onConversionDataFail(_ error: Error) {
        bridge.receiveTracking(["error": true, "error_desc": error.localizedDescription])
    }
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let dl = result.deepLink else { return }
        bridge.receiveNavigation(dl.clickEvent)
    }
}
