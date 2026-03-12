import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = HGSpacing.md
    var radius:  CGFloat = HGRadius.lg
    
    init(padding: CGFloat = HGSpacing.md, radius: CGFloat = HGRadius.lg, @ViewBuilder content: () -> Content) {
        self.content = content(); self.padding = padding; self.radius = radius
    }
    var body: some View {
        content.padding(padding).glassCard(radius)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    var icon: String?  = nil
    var gradient: LinearGradient = HGColor.gradAccent
    var height: CGFloat = 52
    var isLoading = false
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: HGRadius.md)
                    .fill(gradient)
                    .frame(height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: HGRadius.md)
                            .fill(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .center))
                    )
                    .hgShadow(HGShadow.accent)
                
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        if let i = icon { Image(systemName: i).font(.system(size: 15, weight: .semibold)) }
                        Text(title).font(HGFont.heading(16))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(.spring(response: 0.2), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged{_ in pressed=true}.onEnded{_ in pressed=false})
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String; var icon: String? = nil; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let i = icon { Image(systemName: i).font(.system(size: 14, weight: .medium)) }
                Text(title).font(HGFont.heading(15))
            }
            .foregroundColor(HGColor.accent)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(HGColor.accent.opacity(0.1))
            .cornerRadius(HGRadius.md)
            .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.accent.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
        .pressAnimation()
    }
}

// MARK: - Icon Button
struct IconBtn: View {
    let icon: String; var color: Color = HGColor.accent; var size: CGFloat = 44; let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: size, height: size)
                    .overlay(Circle().stroke(color.opacity(0.2), lineWidth: 1))
                Image(systemName: icon).font(.system(size: size*0.38, weight: .semibold)).foregroundColor(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .pressAnimation()
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String; let color: Color; var small: Bool = false
    var body: some View {
        Text(text)
            .font(small ? HGFont.body(10, weight: .bold) : HGFont.body(12, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, small ? 8 : 12)
            .padding(.vertical, small ? 3 : 5)
            .background(color.opacity(0.15))
            .cornerRadius(HGRadius.round)
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String; var subtitle: String? = nil; var action: (() -> Void)? = nil; var actionLabel = "See All"
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(HGFont.heading(17)).foregroundColor(HGColor.textPrimary)
                if let s = subtitle { Text(s).font(HGFont.body(13)).foregroundColor(HGColor.textSecondary) }
            }
            Spacer()
            if let a = action { Button(action: a) { Text(actionLabel).font(HGFont.body(13,weight:.medium)).foregroundColor(HGColor.accent) } }
        }
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let icon: String; let title: String; let message: String; var action: (() -> Void)? = nil; var actionLabel = "Get Started"
    var body: some View {
        VStack(spacing: HGSpacing.lg) {
            ZStack {
                Circle().fill(HGColor.accent.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: icon).font(.system(size: 40, weight: .thin)).foregroundColor(HGColor.textSecondary)
            }
            VStack(spacing: 8) {
                Text(title).font(HGFont.heading(20)).foregroundColor(HGColor.textPrimary)
                Text(message).font(HGFont.body(14)).foregroundColor(HGColor.textSecondary).multilineTextAlignment(.center).padding(.horizontal, HGSpacing.xl)
            }
            if let a = action {
                Button(action: a) {
                    Text(actionLabel).font(HGFont.heading(14)).foregroundColor(HGColor.bg0)
                        .padding(.horizontal, HGSpacing.xl).padding(.vertical, 12)
                        .background(HGColor.gradAccent).cornerRadius(HGRadius.round).hgShadow(HGShadow.accent)
                }
            }
        }
        .padding(HGSpacing.xl).frame(maxWidth: .infinity)
    }
}

// MARK: - Photo Grid
struct PhotoGrid: View {
    let photos: [Data]; var onAdd: (() -> Void)? = nil; var onDelete: ((Int) -> Void)? = nil
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
            ForEach(0..<photos.count, id: \.self) { i in
                if let img = UIImage(data: photos[i]) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(height: 92).clipped().cornerRadius(HGRadius.sm)
                            .overlay(RoundedRectangle(cornerRadius: HGRadius.sm).stroke(HGColor.glassBorder, lineWidth: 0.5))
                        if onDelete != nil {
                            Button(action: { onDelete?(i) }) {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 18))
                                    .foregroundColor(.white).shadow(radius: 3)
                            }.padding(3)
                        }
                    }
                }
            }
            if let onAdd = onAdd {
                Button(action: onAdd) {
                    VStack(spacing: 5) {
                        Image(systemName: "plus").font(.system(size: 20, weight: .medium)).foregroundColor(HGColor.textTertiary)
                        Text("Add").font(HGFont.body(10)).foregroundColor(HGColor.textTertiary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 92)
                    .background(HGColor.glass).cornerRadius(HGRadius.sm)
                    .overlay(RoundedRectangle(cornerRadius: HGRadius.sm).stroke(HGColor.glassBorder, style: StrokeStyle(lineWidth: 1, dash: [5])))
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Pulse Dot
struct PulseDot: View {
    let color: Color; var size: CGFloat = 10
    @State private var pulse = false
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.25)).frame(width: size*2.2, height: size*2.2)
                .scaleEffect(pulse ? 1.4 : 1).opacity(pulse ? 0 : 0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
            Circle().fill(color).frame(width: size, height: size)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Glowing Number
struct GlowNumber: View {
    let value: String; let label: String; var color: Color = HGColor.accent
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(HGFont.mono(22)).foregroundColor(color)
                .shadow(color: color.opacity(0.4), radius: 8)
            Text(label).font(HGFont.body(11)).foregroundColor(HGColor.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, HGSpacing.md).glassCard()
    }
}

// MARK: - Cost Tag
struct CostTag: View {
    let amount: Double; var currency = "USD"
    var symbol: String { currency == "EUR" ? "€" : currency == "GBP" ? "£" : "$" }
    var body: some View {
        Text("\(symbol)\(amount >= 1000 ? String(format:"%.1fk", amount/1000) : String(format:"%.0f", amount))")
            .font(HGFont.mono(14))
            .foregroundColor(HGColor.accent)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(HGColor.accent.opacity(0.12)).cornerRadius(HGRadius.round)
            .overlay(Capsule().stroke(HGColor.accent.opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Animated Hero Background
struct HeroBackground: View {
    var color1: Color = Color(hex: "#F5A623")
    var color2: Color = Color(hex: "#4ECDC4")
    @State private var anim = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                HGColor.gradHero.ignoresSafeArea()
                Circle().fill(color1.opacity(0.08)).frame(width:500).blur(radius:100).offset(x: anim ? 60:30, y: anim ? -220:-200)
                    .animation(.easeInOut(duration:6).repeatForever(autoreverses:true), value:anim)
                Circle().fill(color2.opacity(0.06)).frame(width:400).blur(radius:80).offset(x: anim ? -80:-50, y: anim ? 260:230)
                    .animation(.easeInOut(duration:8).repeatForever(autoreverses:true), value:anim)
                // Subtle grid
                Canvas { ctx, size in
                    let s: CGFloat = 40
                    var y: CGFloat = 0
                    while y < size.height {
                        var x: CGFloat = 0
                        while x < size.width {
                            ctx.stroke(Path { p in p.move(to: CGPoint(x:x,y:0)); p.addLine(to: CGPoint(x:x,y:size.height)) }, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
                            x += s
                        }
                        ctx.stroke(Path { p in p.move(to: CGPoint(x:0,y:y)); p.addLine(to: CGPoint(x:size.width,y:y)) }, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
                        y += s
                    }
                }.ignoresSafeArea()
            }
            .onAppear { anim = true }
            .frame(width: geo.size.width)
        }
    }
}

// MARK: - Tab Screen Header
struct ScreenHeader: View {
    let title: String; var subtitle: String? = nil; var icon: String? = nil
    var trailing: AnyView? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            HeroBackground()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(HGColor.accent)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(HGColor.accent.opacity(0.12)).cornerRadius(HGRadius.round)
                    }
                    Text(title).font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(HGColor.textPrimary)
                    if let s = subtitle { Text(s).font(HGFont.body(13)).foregroundColor(HGColor.textSecondary) }
                }
                Spacer()
                if let t = trailing { t }
            }
            .padding(.horizontal, HGSpacing.md)
            .padding(.top, 56)
            .padding(.bottom, HGSpacing.md)
        }
        .frame(height: 130)
    }
}

// MARK: - Form Field (dark)
struct DarkTextField: View {
    let label: String; let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var axis: Axis = .horizontal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(HGFont.body(11, weight: .semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
            TextField(placeholder, text: $text, axis: axis)
                .font(HGFont.body(15)).foregroundColor(HGColor.textPrimary)
                .keyboardType(keyboard).autocapitalization(.none).disableAutocorrection(true)
                .padding(HGSpacing.md)
                .background(HGColor.bg2).cornerRadius(HGRadius.md)
                .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.glassBorder, lineWidth: 1))
        }
    }
}

// MARK: - Chip selector
struct ChipSelector<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let items: [T]; @Binding var selected: T; var color: Color = HGColor.accent
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button(action: { withAnimation(.spring(response: 0.3)) { selected = item } }) {
                        Text(item.rawValue)
                            .font(HGFont.body(13, weight: selected == item ? .semibold : .regular))
                            .foregroundColor(selected == item ? HGColor.bg0 : HGColor.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selected == item ? color : HGColor.bg2)
                            .cornerRadius(HGRadius.round)
                            .overlay(Capsule().stroke(selected == item ? Color.clear : HGColor.glassBorder, lineWidth: 1))
                    }.buttonStyle(PlainButtonStyle())
                }
            }.padding(.horizontal, HGSpacing.md)
        }
    }
}

// MARK: - Shimmer
struct ShimmerView: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [HGColor.bg2, HGColor.bg3, HGColor.bg2], startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 3)
                .offset(x: phase * geo.size.width * 1.5)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
        }
        .onAppear { phase = 1 }
        .cornerRadius(HGRadius.sm)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let onPick: (Data?) -> Void
    var source: UIImagePickerController.SourceType = .photoLibrary
    
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? source : .photoLibrary
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (Data?) -> Void
        init(onPick: @escaping (Data?) -> Void) { self.onPick = onPick }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                let sz = CGSize(width: 1200, height: 1200 * img.size.height / img.size.width)
                UIGraphicsBeginImageContextWithOptions(sz, false, 1)
                img.draw(in: CGRect(origin: .zero, size: sz))
                let r = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                onPick((r ?? img).jpegData(compressionQuality: 0.75))
            } else { onPick(nil) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onPick(nil); picker.dismiss(animated: true) }
    }
}

// MARK: - Notification service
class NotificationService {
    static let shared = NotificationService()
    func schedule(_ r: Reminder) {
        let c = UNMutableNotificationContent(); c.title = "🏠 HomeGuard"; c.body = r.title; c.sound = .default
        let comp = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: r.nextDueDate)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: r.notificationId, content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)))
    }
    func cancel(_ id: String) { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id]) }
}

// MARK: - PDF Export
class PDFExportService {
    static func export(entries: [JournalEntry], property: Property?) -> Data? {
        let rect = CGRect(x:0,y:0,width:612,height:792)
        return UIGraphicsPDFRenderer(bounds: rect).pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 60
            let h1: [NSAttributedString.Key:Any] = [.font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: UIColor.white]
            let h2: [NSAttributedString.Key:Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray]
            let body: [NSAttributedString.Key:Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
            
            "🏠 HomeGuard Maintenance Journal".draw(at: CGPoint(x:50,y:y), withAttributes: h1); y += 36
            if let p = property { "Property: \(p.name) · Generated \(Date().formatted(.dateTime.month().day().year()))".draw(at: CGPoint(x:50,y:y), withAttributes: h2); y += 28 }
            
            for e in entries {
                if y > 700 { ctx.beginPage(); y = 60 }
                let meta = "\(e.date.formatted(.dateTime.month(.abbreviated).day().year())) · \(e.workType.rawValue)\(e.cost.map { " · $\(Int($0))" } ?? "")"
                e.title.draw(at: CGPoint(x:50,y:y), withAttributes: [.font: UIFont.systemFont(ofSize:14,weight:.semibold), .foregroundColor: UIColor.white]); y += 20
                meta.draw(at: CGPoint(x:50,y:y), withAttributes: h2); y += 18
                if !e.description.isEmpty { e.description.draw(in: CGRect(x:50,y:y,width:512,height:32), withAttributes: body); y += 28 }
                y += 12
            }
        }
    }
}
