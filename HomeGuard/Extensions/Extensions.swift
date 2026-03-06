import SwiftUI
import Foundation

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var daysFromNow: Int { Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0 }
}

extension View {
    func cardStyle() -> some View { self.padding(HGSpacing.md).glassCard() }
    func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
}

extension Double {
    var currencyString: String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: self)) ?? "$\(Int(self))"
    }
}

extension String {
    var isNotEmpty: Bool { !isEmpty }
}

// MARK: - Blur modifier
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
