import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()
            
            Group {
                switch authService.authState {
                case .unknown:
                    SplashView()
                        .transition(.opacity)
                        
                case .unauthenticated:
                    if !appState.hasCompletedOnboarding {
                        OnboardingContainerView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.97)),
                                removal:   .opacity.combined(with: .scale(scale: 1.03))
                            ))
                    } else {
                        AuthRootView()
                            .transition(.opacity)
                    }
                    
                case .authenticated:
                    if appState.showingSplash {
                        SplashView()
                            .transition(.opacity)
                    } else if !appState.hasCompletedOnboarding {
                        OnboardingContainerView()
                            .transition(.opacity)
                    } else {
                        MainTabView()
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: authService.authState.rawValue)
            .animation(.easeInOut(duration: 0.4), value: appState.showingSplash)
        }
    }
}

extension AuthState {
    var rawValue: Int {
        switch self {
        case .unknown: return 0
        case .unauthenticated: return 1
        case .authenticated: return 2
        }
    }
}
