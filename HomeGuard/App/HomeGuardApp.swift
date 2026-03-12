import SwiftUI
import UserNotifications

struct HomeConfig {
    static let appID = "6760190029"
    static let devKey = "pegmrjRdAJvds5T6esr6mC"
}

@main
struct HomeGuardApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState   = AppStateManager()
    @StateObject private var propertyStore = PropertyStore()
    @StateObject private var reminderStore = ReminderStore()
    @StateObject private var journalStore  = JournalStore()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegeteApp
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authService)
                .environmentObject(appState)
                .environmentObject(propertyStore)
                .environmentObject(reminderStore)
                .environmentObject(journalStore)
                .preferredColorScheme(.dark)  // Always dark for our premium aesthetic
        }
    }
    
}

// MARK: - App State Manager
class AppStateManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hg.onboarding") }
    }
    @Published var showingSplash = true
    @Published var selectedTab   = 0
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hg.onboarding")
    }
    func completeOnboarding() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { hasCompletedOnboarding = true }
    }
}

final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["target_url"] as? String { return u }
        return nil
    }
}
