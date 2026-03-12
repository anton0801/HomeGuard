import SwiftUI
import Combine

struct SplashView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authService: AuthService
    
    @State private var logoScale: CGFloat   = 0.0
    @State private var logoOpacity: Double  = 0.0
    @State private var ringScale1: CGFloat  = 0.3
    @State private var ringScale2: CGFloat  = 0.3
    @State private var ringOpacity: Double  = 0.0
    @State private var textOpacity: Double  = 0.0
    @State private var textOffset: CGFloat  = 30
    @State private var subOpacity: Double   = 0.0
    @State private var particles: [SplashParticle] = SplashParticle.generate(40)
    @State private var beamRotation: Double = 0
    @State private var shimmer: CGFloat     = -1.0
    
    @StateObject private var store = Store()
    @State private var streams = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "#060D18").ignoresSafeArea()
                
                
                GeometryReader { geo in
                    Image("main_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .opacity(0.3)
                        .blur(radius: 8)
                }
                .ignoresSafeArea()
                
                // Radial gradient glow center
                RadialGradient(
                    colors: [
                        Color(hex: "#F5A623").opacity(0.12),
                        Color(hex: "#0A1628").opacity(0),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
                
                // Rotating light beams
                ForEach(0..<3) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(hex: "#F5A623").opacity(0.05), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: 2, height: 600)
                        .rotationEffect(.degrees(beamRotation + Double(i) * 60))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: beamRotation)
                }
                
                // Particles
                ForEach(particles) { p in
                    SplashParticleView(particle: p)
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo container
                    ZStack {
                        // Ring 1
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.clear, Color(hex: "#F5A623").opacity(0.6), .clear],
                                    center: .center
                                ),
                                lineWidth: 1
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(ringScale1)
                            .opacity(ringOpacity)
                        
                        // Ring 2
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.clear, Color(hex: "#4ECDC4").opacity(0.4), .clear],
                                    center: .center
                                ),
                                lineWidth: 0.5
                            )
                            .frame(width: 220, height: 220)
                            .scaleEffect(ringScale2)
                            .opacity(ringOpacity * 0.6)
                        
                        // Core logo
                        ZStack {
                            // Glow backdrop
                            Circle()
                                .fill(Color(hex: "#F5A623").opacity(0.15))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                            
                            // Hex background
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#162A47"), Color(hex: "#0F1E35")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color(hex: "#F5A623").opacity(0.5), Color(hex: "#4ECDC4").opacity(0.3)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .hgShadow(HGShadow.lg)
                            
                            // Shimmer overlay
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.12), .clear],
                                        startPoint: .init(x: shimmer, y: 0),
                                        endPoint: .init(x: shimmer + 0.5, y: 1)
                                    )
                                )
                                .frame(width: 110, height: 110)
                            
                            // Icon
                            VStack(spacing: 2) {
                                Image("logo")
                                    .resizable()
                                    .frame(width: 100, height: 60)
                                
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(HGColor.gradCool)
                                    .offset(y: -4)
                            }
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    }
                    
                    Spacer().frame(height: 48)
                    
                    // App name
                    VStack(spacing: 10) {
                        HStack(spacing: 0) {
                            Text("Loa")
                                .font(.system(size: 44, weight: .medium, design: .rounded))
                                .foregroundColor(HGColor.textPrimary)
                            Text("Ding...")
                                .font(.system(size: 44, weight: .black, design: .serif))
                                .foregroundStyle(HGColor.gradAccent)
                        }
                        .offset(y: textOffset)
                        .opacity(textOpacity)
                        
                        Text("YOUR HOME'S BUILDING FORTRESS")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(HGColor.textSecondary)
                            .tracking(3)
                            .opacity(subOpacity)
                    }
                    
                    Spacer()
                    
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<5) { i in
                            BounceDot(index: i)
                        }
                    }
                    .opacity(subOpacity)
                    .padding(.bottom, 60)
                }
                
                NavigationLink(
                    destination: HomeWebView().navigationBarHidden(true),
                    isActive: $store.state.ui.navigateToWeb
                ) { EmptyView() }

                NavigationLink(
                    destination: RootView().navigationBarBackButtonHidden(true),
                    isActive: $store.state.ui.navigateToMain
                ) { EmptyView() }
            }
            .onAppear {
                animate()
                store.dispatch(.initialize)
                setupStreams()
            }
            .fullScreenCover(isPresented: $store.state.ui.showPermissionPrompt) {
                HomeNotificationView(store: store)
            }
            .fullScreenCover(isPresented: $store.state.ui.showOfflineView) {
                WiFiOffScreenView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func animate() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            beamRotation = 360
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            ringScale1 = 1.0; ringOpacity = 1.0
        }
        withAnimation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.2)) {
            ringScale2 = 1.0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.3)) {
            logoScale = 1.0; logoOpacity = 1.0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
            textOffset = 0; textOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            subOpacity = 1.0
        }
        withAnimation(.linear(duration: 0.8).delay(0.9)) {
            shimmer = 1.5
        }
    }
    
    private func setupStreams() {
        NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { store.dispatch(.trackingReceived($0)) }
            .store(in: &streams)
        
        NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { store.dispatch(.navigationReceived($0)) }
            .store(in: &streams)
    }
    
}

struct WiFiOffScreenView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("main_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .opacity(0.6)
                    .blur(radius: 8)
                
                Image("alert_connection")
                    .resizable()
                    .frame(width: 215, height: 185)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}

// MARK: - Splash Particle
struct SplashParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    
    static func generate(_ n: Int) -> [SplashParticle] {
        (0..<n).map { _ in
            SplashParticle(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: -400...400),
                size: CGFloat.random(in: 2...6),
                color: [Color(hex: "#F5A623"), Color(hex: "#4ECDC4"), Color(hex: "#FF7B4C")].randomElement()!,
                opacity: Double.random(in: 0.1...0.45)
            )
        }
    }
}

struct SplashParticleView: View {
    let particle: SplashParticle
    @State private var float = false
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .opacity(float ? particle.opacity : 0)
            .offset(x: particle.x, y: float ? particle.y - 30 : particle.y + 30)
            .blur(radius: particle.size > 4 ? 1.5 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2.5...5))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2))
                ) { float = true }
            }
    }
}

// MARK: - Bounce Dot
struct BounceDot: View {
    let index: Int
    @State private var bouncing = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(HGColor.gradAccent)
            .frame(width: bouncing ? 20 : 6, height: 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.12), value: bouncing)
            .onAppear { bouncing = true }
    }
}
