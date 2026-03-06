import SwiftUI
import UserNotifications

@main
struct HomeGuardApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState   = AppStateManager()
    @StateObject private var propertyStore = PropertyStore()
    @StateObject private var reminderStore = ReminderStore()
    @StateObject private var journalStore  = JournalStore()
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { _,_ in }
        setupTabBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(appState)
                .environmentObject(propertyStore)
                .environmentObject(reminderStore)
                .environmentObject(journalStore)
                .preferredColorScheme(.dark)  // Always dark for our premium aesthetic
        }
    }
    
    private func setupTabBarAppearance() {
        let a = UITabBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = UIColor(red: 0.04, green: 0.08, blue: 0.15, alpha: 0.97)
        UITabBar.appearance().standardAppearance = a
        if #available(iOS 15, *) { UITabBar.appearance().scrollEdgeAppearance = a }
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
