import SwiftUI

// MARK: - Premium Color System
struct HGColor {
    // Core brand — luxury midnight blue + electric amber
    static let primary       = Color(hex: "#0A1628")   // Midnight
    static let primaryMid    = Color(hex: "#112240")   // Deep navy
    static let primaryLight  = Color(hex: "#1D3461")   // Navy
    static let accent        = Color(hex: "#F5A623")   // Electric amber
    static let accentWarm    = Color(hex: "#FF7B4C")   // Coral fire
    static let accentCool    = Color(hex: "#4ECDC4")   // Teal spark

    // Surfaces — layered glass
    static let glass         = Color.white.opacity(0.06)
    static let glassBorder   = Color.white.opacity(0.12)
    static let glassBright   = Color.white.opacity(0.1)
    static let glassDeep     = Color.black.opacity(0.3)
    
    // Background ecosystem
    static let bg0           = Color(hex: "#060D18")   // Deepest
    static let bg1           = Color(hex: "#0A1628")   // Base
    static let bg2           = Color(hex: "#0F1E35")   // Surface
    static let bg3           = Color(hex: "#162A47")   // Card
    
    // Semantic
    static let success       = Color(hex: "#23D18B")   // Neon green
    static let warning       = Color(hex: "#F5A623")   // Amber
    static let danger        = Color(hex: "#FF4C6A")   // Hot red
    static let info          = Color(hex: "#4ECDC4")   // Teal
    
    // Text hierarchy
    static let textPrimary   = Color(hex: "#F0F4FF")
    static let textSecondary = Color(hex: "#8896B0")
    static let textTertiary  = Color(hex: "#4A5568")
    static let textMuted     = Color(hex: "#2D3748")

    // Premium gradients
    static let gradHero = LinearGradient(
        colors: [Color(hex: "#060D18"), Color(hex: "#0F2040"), Color(hex: "#060D18")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradAccent = LinearGradient(
        colors: [Color(hex: "#F5A623"), Color(hex: "#FF7B4C")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradAccentVert = LinearGradient(
        colors: [Color(hex: "#F5A623"), Color(hex: "#FF7B4C")],
        startPoint: .top, endPoint: .bottom
    )
    static let gradCool = LinearGradient(
        colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradSuccess = LinearGradient(
        colors: [Color(hex: "#23D18B"), Color(hex: "#16A96D")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradDanger = LinearGradient(
        colors: [Color(hex: "#FF4C6A"), Color(hex: "#C62A47")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradCard = LinearGradient(
        colors: [Color(hex: "#162A47").opacity(0.9), Color(hex: "#0F1E35").opacity(0.95)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradGlass = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    // Glow colors
    static let glowAccent  = Color(hex: "#F5A623").opacity(0.35)
    static let glowCool    = Color(hex: "#4ECDC4").opacity(0.25)
    static let glowDanger  = Color(hex: "#FF4C6A").opacity(0.30)
    static let glowSuccess = Color(hex: "#23D18B").opacity(0.25)
}

// MARK: - Typography
struct HGFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func heading(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Spacing
struct HGSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius
struct HGRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 40
    static let round: CGFloat = 999
}

// MARK: - Shadow + Glow system
struct HGShadow {
    static let sm  = ShadowDef(color: Color.black.opacity(0.4), radius: 8,  x: 0, y: 4)
    static let md  = ShadowDef(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 8)
    static let lg  = ShadowDef(color: Color.black.opacity(0.6), radius: 40, x: 0, y: 16)
    static let accent = ShadowDef(color: HGColor.glowAccent, radius: 20, x: 0, y: 6)
    static let cool   = ShadowDef(color: HGColor.glowCool,   radius: 20, x: 0, y: 6)
    static let danger = ShadowDef(color: HGColor.glowDanger,  radius: 20, x: 0, y: 6)
}
struct ShadowDef {
    let color: Color; let radius: CGFloat; let x: CGFloat; let y: CGFloat
}

// MARK: - View helpers
extension View {
    func hgShadow(_ s: ShadowDef) -> some View {
        self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
    func glassCard(_ cornerRadius: CGFloat = HGRadius.lg) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    func accentGlow() -> some View {
        self.hgShadow(HGShadow.accent)
    }
    func pressAnimation() -> some View {
        self.modifier(PressAnimationModifier())
    }
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(HGColor.gradCard)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(HGColor.gradGlass)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(HGColor.glassBorder, lineWidth: 1)
                }
            )
            .hgShadow(HGShadow.md)
    }
}

// MARK: - Press Animation
struct PressAnimationModifier: ViewModifier {
    @State private var pressed = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded   { _ in pressed = false }
            )
    }
}

// MARK: - Color Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
