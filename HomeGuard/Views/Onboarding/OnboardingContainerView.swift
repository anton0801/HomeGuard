import SwiftUI

#Preview {
    OnboardingContainerView()
        .environmentObject(AppStateManager())
}

struct OnboardingContainerView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var page = 0
    
    let pages = OnboardingData.all
    
    var body: some View {
        ZStack {
            // Dynamic background color per page
            Color(hex: "#060D18").ignoresSafeArea()
            
            ForEach(0..<pages.count) { i in
                pages[i].background
                    .ignoresSafeArea()
                    .opacity(page == i ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: page)
            }
            
            TabView(selection: $page) {
                ForEach(0..<pages.count, id: \.self) { i in
                    OnboardingPageView(data: pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Bottom UI overlay
            VStack {
                Spacer()
                VStack(spacing: HGSpacing.lg) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? HGColor.accent : HGColor.textMuted)
                                .frame(width: i == page ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                        }
                    }
                    
                    // Buttons
                    HStack(spacing: HGSpacing.md) {
                        if page < pages.count - 1 {
                            Button(action: {
                                withAnimation(.spring()) { appState.completeOnboarding() }
                            }) {
                                Text("Skip")
                                    .font(HGFont.body(15))
                                    .foregroundColor(HGColor.textSecondary)
                                    .padding(.horizontal, HGSpacing.md)
                                    .padding(.vertical, 14)
                            }
                        }
                        
                        Button(action: {
                            if page < pages.count - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { page += 1 }
                            } else {
                                withAnimation(.spring()) { appState.completeOnboarding() }
                            }
                        }) {
                            HStack(spacing: 10) {
                                Text(page < pages.count - 1 ? "Next" : "Let's Begin")
                                    .font(HGFont.heading(16))
                                Image(systemName: page < pages.count - 1 ? "arrow.right" : "house.fill")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(HGColor.bg0)
                            .frame(maxWidth: page < pages.count - 1 ? nil : 250)
                            .padding(.horizontal, HGSpacing.xl)
                            .padding(.vertical, 16)
                            .background(HGColor.gradAccent)
                            .cornerRadius(HGRadius.round)
                            .hgShadow(HGShadow.accent)
                        }
                    }
                }
                .padding(.horizontal, HGSpacing.lg)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Onboarding Page Data
struct OnboardingPageData {
    let title: String
    let highlight: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let background: AnyView
    let accentColor: Color
}

struct OnboardingData {
    static let all: [OnboardingPageData] = [
        .init(
            title: "Your Home's", highlight: "Digital Passport",
            subtitle: "Document everything about your property — from construction materials to floor plans. All in one secure place.",
            icon: "house.and.flag.fill",
            gradient: HGColor.gradAccent,
            background: AnyView(OnboardingBG(color1: Color(hex: "#F5A623"), color2: Color(hex: "#FF7B4C"))),
            accentColor: Color(hex: "#F5A623")
        ),
        .init(
            title: "Track Every", highlight: "Maintenance Task",
            subtitle: "Seasonal checklists, custom reminders, and push notifications keep your home in perfect condition year-round.",
            icon: "calendar.badge.checkmark",
            gradient: HGColor.gradCool,
            background: AnyView(OnboardingBG(color1: Color(hex: "#4ECDC4"), color2: Color(hex: "#44A08D"))),
            accentColor: Color(hex: "#4ECDC4")
        ),
        .init(
            title: "Capture Issues", highlight: "Instantly",
            subtitle: "Spot a crack or leak? Photograph it in-app, flag it, and get AI-powered diagnosis suggestions immediately.",
            icon: "camera.viewfinder",
            gradient: LinearGradient(colors: [Color(hex: "#7B61FF"), Color(hex: "#5A42CC")], startPoint: .leading, endPoint: .trailing),
            background: AnyView(OnboardingBG(color1: Color(hex: "#7B61FF"), color2: Color(hex: "#5A42CC"))),
            accentColor: Color(hex: "#7B61FF")
        ),
        .init(
            title: "Full Repair", highlight: "History",
            subtitle: "Timeline of every job done, with before & after photos, costs, and contractor details. Know your home's full story.",
            icon: "clock.arrow.circlepath",
            gradient: HGColor.gradSuccess,
            background: AnyView(OnboardingBG(color1: Color(hex: "#23D18B"), color2: Color(hex: "#16A96D"))),
            accentColor: Color(hex: "#23D18B")
        ),
        .init(
            title: "Manage All", highlight: "Your Properties",
            subtitle: "Your apartment, parents' house, vacation rental — all tracked in one app. Export full PDF reports anytime.",
            icon: "building.2.crop.circle.fill",
            gradient: LinearGradient(colors: [Color(hex: "#F093FB"), Color(hex: "#F5576C")], startPoint: .leading, endPoint: .trailing),
            background: AnyView(OnboardingBG(color1: Color(hex: "#F093FB"), color2: Color(hex: "#F5576C"))),
            accentColor: Color(hex: "#F093FB")
        )
    ]
}

// MARK: - Onboarding Background
struct OnboardingBG: View {
    let color1: Color; let color2: Color
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Color(hex: "#060D18")
            Circle().fill(color1.opacity(0.12)).frame(width: 500, height: 500)
                .blur(radius: 100).offset(y: -100)
                .scaleEffect(pulse ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulse)
            Circle().fill(color2.opacity(0.08)).frame(width: 400, height: 400)
                .blur(radius: 80).offset(y: 150)
        }
        .onAppear { pulse = true }
        .ignoresSafeArea()
    }
}

// MARK: - Single Onboarding Page
struct OnboardingPageView: View {
    let data: OnboardingPageData
    @State private var iconVisible = false
    @State private var textVisible = false
    @State private var floatUp = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Illustration
            ZStack {
                // Outer ring
                Circle()
                    .stroke(data.accentColor.opacity(0.15), lineWidth: 1)
                    .frame(width: 260, height: 260)
                    .scaleEffect(iconVisible ? 1 : 0.5)
                
                Circle()
                    .stroke(data.accentColor.opacity(0.08), lineWidth: 1)
                    .frame(width: 220, height: 220)
                    .scaleEffect(iconVisible ? 1 : 0.5)
                
                // Icon container
                ZStack {
                    Circle()
                        .fill(data.accentColor.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .blur(radius: 25)
                    
                    RoundedRectangle(cornerRadius: 36)
                        .fill(LinearGradient(colors: [Color(hex: "#162A47"), Color(hex: "#0F1E35")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 140, height: 140)
                        .overlay(RoundedRectangle(cornerRadius: 36).stroke(data.accentColor.opacity(0.3), lineWidth: 1.5))
                        .hgShadow(HGShadow.lg)
                    
                    Image(systemName: data.icon)
                        .font(.system(size: 60, weight: .thin))
                        .foregroundStyle(data.gradient)
                }
                .scaleEffect(iconVisible ? 1 : 0.4)
                .opacity(iconVisible ? 1 : 0)
                .offset(y: floatUp ? -12 : 0)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: iconVisible)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.8), value: floatUp)
            
            Spacer().frame(height: 56)
            
            // Text
            VStack(spacing: HGSpacing.md) {
                VStack(spacing: 6) {
                    Text(data.title)
                        .font(.system(size: 36, weight: .thin, design: .serif))
                        .foregroundColor(HGColor.textPrimary)
                    Text(data.highlight)
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundStyle(data.gradient)
                }
                .multilineTextAlignment(.center)
                
                Text(data.subtitle)
                    .font(HGFont.body(16))
                    .foregroundColor(HGColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, HGSpacing.xl)
            }
            .opacity(textVisible ? 1 : 0)
            .offset(y: textVisible ? 0 : 24)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: textVisible)
            
            Spacer()
            Spacer()
        }
        .padding(.bottom, 160)
        .onAppear {
            iconVisible = true; textVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { floatUp = true }
        }
        .onDisappear { iconVisible = false; textVisible = false; floatUp = false }
    }
}
