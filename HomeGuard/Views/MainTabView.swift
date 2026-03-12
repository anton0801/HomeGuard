import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var reminderStore: ReminderStore
    @State private var selected = 0
    @State private var appeared = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            ZStack {
                switch selected {
                case 0: MyHomeView().transition(.opacity)
                case 1: RemindersView().transition(.opacity)
                case 2: JournalView().transition(.opacity)
                case 3: AnalyticsView().transition(.opacity)
                case 4: ProfileView().transition(.opacity)
                default: MyHomeView()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selected)
            
            // Custom tab bar
            CustomTabBar(selected: $selected, badgeCount: reminderStore.overdueCount)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 40)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { _,_ in }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                appeared = true
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selected: Int
    var badgeCount: Int = 0
    
    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("bell.fill", "Reminders"),
        ("book.closed.fill", "Journal"),
        ("chart.bar.fill", "Analytics"),
        ("person.circle.fill", "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                TabBarButton(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    isSelected: selected == i,
                    badge: i == 1 ? badgeCount : 0
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = i }
                    HapticService.impact(.light)
                }
            }
        }
        .padding(.horizontal, HGSpacing.md)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            ZStack {
                Rectangle()
                    .fill(Color(hex: "#060D18").opacity(0.96))
                    .ignoresSafeArea(edges: .bottom)
                Rectangle()
                    .fill(LinearGradient(colors: [HGColor.glassBorder, .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: -5)
    }
}

struct TabBarButton: View {
    let icon: String; let label: String; let isSelected: Bool
    var badge: Int = 0; let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        // Glow bg when selected
                        if isSelected {
                            RoundedRectangle(cornerRadius: HGRadius.sm)
                                .fill(HGColor.accent.opacity(0.15))
                                .frame(width: 48, height: 32)
                        }
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? HGColor.accent : HGColor.textTertiary)
                            .shadow(color: isSelected ? HGColor.glowAccent : .clear, radius: 8)
                            .scaleEffect(pressed ? 0.88 : (isSelected ? 1.05 : 1.0))
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
                    }
                    .frame(width: 48, height: 32)
                    
                    if badge > 0 {
                        ZStack {
                            Circle().fill(HGColor.danger).frame(width: 16, height: 16)
                            Text("\(min(badge, 9))").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? HGColor.accent : HGColor.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged{_ in pressed=true}.onEnded{_ in pressed=false})
    }
}

// MARK: - Haptic
struct HapticService {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
