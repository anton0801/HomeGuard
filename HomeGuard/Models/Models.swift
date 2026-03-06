import SwiftUI
import Foundation

// MARK: - Property
struct Property: Identifiable, Codable {
    var id        = UUID()
    var name:       String
    var type:       PropertyType
    var yearBuilt:  Int?
    var totalArea:  Double?
    var areaUnit:   AreaUnit     = .squareMeters
    var address:    String       = ""
    var wallMaterial:  String    = ""
    var floorMaterial: String    = ""
    var roofMaterial:  String    = ""
    var rooms:         [Room]    = []
    var warranties:    [Warranty] = []
    var documents:     [HomeDocument] = []
    var photoDataList: [Data]    = []
    var createdAt: Date          = Date()
    
    var overallStatus: RoomStatus {
        rooms.contains(where: { $0.status == .needsAttention }) ? .needsAttention : .allGood
    }
}

enum PropertyType: String, Codable, CaseIterable {
    case apartment = "Apartment"; case house = "House"
    case townhouse = "Townhouse"; case condo = "Condo"; case cottage = "Cottage"
    var icon: String {
        switch self {
        case .apartment: return "building.2"; case .house: return "house.fill"
        case .townhouse: return "building"; case .condo: return "building.columns"
        case .cottage: return "house.lodge.fill"
        }
    }
}
enum AreaUnit: String, Codable, CaseIterable { case squareMeters = "m²"; case squareFeet = "ft²" }

// MARK: - Room
struct Room: Identifiable, Codable {
    var id     = UUID()
    var name:    String
    var type:    RoomType
    var status:  RoomStatus  = .allGood
    var notes:   String      = ""
    var lastChecked: Date?
    var photoDataList: [Data] = []
}

enum RoomType: String, Codable, CaseIterable {
    case livingRoom="Living Room"; case bedroom="Bedroom"; case kitchen="Kitchen"
    case bathroom="Bathroom"; case garage="Garage"; case basement="Basement"
    case attic="Attic"; case office="Office"; case laundry="Laundry"; case other="Other"
    var icon: String {
        switch self {
        case .livingRoom: return "sofa.fill"; case .bedroom: return "bed.double.fill"
        case .kitchen: return "fork.knife"; case .bathroom: return "shower.fill"
        case .garage: return "car.2.fill"; case .basement: return "arrow.down.square.fill"
        case .attic: return "arrow.up.square.fill"; case .office: return "desktopcomputer"
        case .laundry: return "washer.fill"; case .other: return "square.dashed"
        }
    }
    var color: Color {
        switch self {
        case .livingRoom: return Color(hex: "#F5A623"); case .bedroom: return Color(hex: "#7B61FF")
        case .kitchen: return Color(hex: "#FF7B4C"); case .bathroom: return Color(hex: "#4ECDC4")
        case .garage: return Color(hex: "#8896B0"); case .basement: return Color(hex: "#44A08D")
        case .attic: return Color(hex: "#F093FB"); case .office: return Color(hex: "#3A7FBF")
        case .laundry: return Color(hex: "#23D18B"); case .other: return Color(hex: "#6B6B80")
        }
    }
}

enum RoomStatus: String, Codable {
    case allGood = "All Good"; case needsAttention = "Needs Attention"
    var color: Color { self == .allGood ? HGColor.success : HGColor.warning }
    var icon:  String { self == .allGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill" }
}

// MARK: - Warranty
struct Warranty: Identifiable, Codable {
    var id = UUID()
    var itemName: String; var purchaseDate: Date; var expiryDate: Date
    var notes: String = ""; var photoData: Data?; var brand: String = ""; var modelNumber: String = ""
    var daysUntilExpiry: Int { Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0 }
    var status: WarrantyStatus {
        let d = daysUntilExpiry
        if d < 0 { return .expired }; if d <= 30 { return .expiringSoon }; return .active
    }
}
enum WarrantyStatus {
    case active, expiringSoon, expired
    var color: Color {
        switch self { case .active: return HGColor.success; case .expiringSoon: return HGColor.warning; case .expired: return HGColor.danger }
    }
    var label: String {
        switch self { case .active: return "Active"; case .expiringSoon: return "Expiring Soon"; case .expired: return "Expired" }
    }
    var icon: String {
        switch self { case .active: return "checkmark.shield.fill"; case .expiringSoon: return "exclamationmark.shield.fill"; case .expired: return "xmark.shield.fill" }
    }
}

// MARK: - Home Document
struct HomeDocument: Identifiable, Codable {
    var id = UUID(); var name: String; var type: DocumentType; var data: Data?
    var uploadedAt: Date = Date(); var notes: String = ""
}
enum DocumentType: String, Codable, CaseIterable {
    case wiring="Wiring"; case plumbing="Plumbing"; case blueprint="Blueprint"
    case inspection="Inspection"; case insurance="Insurance"; case other="Other"
    var icon: String {
        switch self { case .wiring: return "bolt.fill"; case .plumbing: return "drop.fill"
        case .blueprint: return "doc.plaintext.fill"; case .inspection: return "magnifyingglass.circle.fill"
        case .insurance: return "shield.fill"; case .other: return "doc.fill" }
    }
    var color: Color {
        switch self { case .wiring: return Color(hex: "#F5A623"); case .plumbing: return Color(hex: "#4ECDC4")
        case .blueprint: return Color(hex: "#3A7FBF"); case .inspection: return Color(hex: "#7B61FF")
        case .insurance: return HGColor.success; case .other: return HGColor.textSecondary }
    }
}

// MARK: - Reminder
struct Reminder: Identifiable, Codable {
    var id = UUID(); var title: String; var details: String = ""
    var category: ReminderCategory; var recurrence: ReminderRecurrence
    var nextDueDate: Date; var isCompleted: Bool = false; var completedDates: [Date] = []
    var propertyId: UUID?; var isBuiltIn: Bool = false; var notificationId: String = UUID().uuidString
    
    var isOverdue: Bool { !isCompleted && nextDueDate < Date() }
    var daysUntilDue: Int { Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0 }
    var urgency: UrgencyLevel {
        if isOverdue { return .overdue }
        let d = daysUntilDue
        if d <= 7 { return .urgent }; if d <= 30 { return .soon }; return .upcoming
    }
}
enum ReminderCategory: String, Codable, CaseIterable {
    case spring="Spring"; case summer="Summer"; case fall="Fall"; case winter="Winter"
    case monthly="Monthly"; case yearly="Yearly"; case custom="Custom"
    var icon: String {
        switch self { case .spring: return "leaf.fill"; case .summer: return "sun.max.fill"
        case .fall: return "wind"; case .winter: return "snowflake"; case .monthly: return "calendar.circle.fill"
        case .yearly: return "repeat.circle.fill"; case .custom: return "bell.badge.fill" }
    }
    var color: Color {
        switch self { case .spring: return Color(hex: "#23D18B"); case .summer: return Color(hex: "#F5A623")
        case .fall: return Color(hex: "#FF7B4C"); case .winter: return Color(hex: "#4ECDC4")
        case .monthly: return Color(hex: "#7B61FF"); case .yearly: return Color(hex: "#F093FB")
        case .custom: return Color(hex: "#FF4C6A") }
    }
}
enum ReminderRecurrence: String, Codable, CaseIterable {
    case oneTime="One-time"; case weekly="Weekly"; case monthly="Monthly"; case quarterly="Quarterly"; case yearly="Yearly"
    var calendarComponent: Calendar.Component {
        switch self { case .oneTime,.weekly: return .weekOfYear; case .monthly,.quarterly: return .month; case .yearly: return .year }
    }
    var value: Int { switch self { case .oneTime: return 0; case .weekly: return 1; case .monthly: return 1; case .quarterly: return 3; case .yearly: return 1 } }
}
enum UrgencyLevel {
    case overdue, urgent, soon, upcoming
    var color: Color {
        switch self { case .overdue: return HGColor.danger; case .urgent: return HGColor.warning
        case .soon: return Color(hex: "#F5A623"); case .upcoming: return HGColor.info }
    }
}

// MARK: - Journal Entry
struct JournalEntry: Identifiable, Codable {
    var id = UUID(); var title: String; var description: String = ""; var date: Date
    var cost: Double?; var currency: String = "USD"; var workType: WorkType
    var propertyId: UUID?; var roomId: UUID?
    var contractorName: String = ""; var contractorContact: String = ""
    var beforePhotoDataList: [Data] = []; var afterPhotoDataList: [Data] = []
    var needsAttention: Bool = false; var issueType: IssueType?; var tags: [String] = []
    var createdAt: Date = Date()
}
enum WorkType: String, Codable, CaseIterable {
    case repair="Repair"; case maintenance="Maintenance"; case improvement="Improvement"
    case inspection="Inspection"; case cleaning="Cleaning"; case installation="Installation"
    case emergency="Emergency"; case other="Other"
    var icon: String {
        switch self { case .repair: return "wrench.and.screwdriver.fill"; case .maintenance: return "gearshape.fill"
        case .improvement: return "star.fill"; case .inspection: return "magnifyingglass.circle.fill"
        case .cleaning: return "sparkles"; case .installation: return "plus.circle.fill"
        case .emergency: return "exclamationmark.triangle.fill"; case .other: return "ellipsis.circle.fill" }
    }
    var color: Color {
        switch self { case .repair: return Color(hex: "#FF7B4C"); case .maintenance: return Color(hex: "#4ECDC4")
        case .improvement: return Color(hex: "#F5A623"); case .inspection: return Color(hex: "#7B61FF")
        case .cleaning: return Color(hex: "#23D18B"); case .installation: return Color(hex: "#F093FB")
        case .emergency: return Color(hex: "#FF4C6A"); case .other: return HGColor.textSecondary }
    }
    var gradient: LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
enum IssueType: String, Codable, CaseIterable {
    case crack="Crack"; case leak="Leak"; case mold="Mold"; case dampness="Dampness"
    case electrical="Electrical"; case pest="Pest"; case structural="Structural"; case other="Other"
    var suggestions: [String] {
        switch self {
        case .crack: return ["Possible causes: foundation settling, thermal expansion/contraction","Check if crack is growing — mark endpoints with pencil and date","Horizontal basement wall cracks can indicate serious structural issues","Hairline plaster cracks are usually cosmetic in older homes"]
        case .leak: return ["Possible causes: pipe corrosion, loose fittings, damaged seals","Locate main water shutoff before calling a plumber","Check water meter before/after 2 hours of no-use to confirm hidden leak","Ceiling discoloration may indicate slow leak from floor above"]
        case .mold: return ["Possible causes: poor ventilation, humidity above 60%, hidden leaks","Use dehumidifier and improve ventilation in affected areas","Small patches: treat with diluted bleach solution (1:10 ratio)","Black mold (Stachybotrys) requires professional remediation"]
        case .dampness: return ["Possible causes: condensation, groundwater infiltration, poor drainage","Ensure gutters direct water 6+ feet away from foundation","Improve ventilation; use exhaust fans in wet areas","Consider waterproof sealant on basement walls"]
        case .electrical: return ["Do NOT attempt electrical repairs without a qualified electrician","Flickering lights may indicate loose wiring or overloaded circuit","GFCI outlets protect bathrooms and kitchens from electrocution","Burning smell near outlets is a serious hazard — call immediately"]
        case .pest: return ["Identify entry points and seal with steel wool or caulk","Store food in airtight containers; fix all moisture issues","Termite damage is often hidden — hollow-sounding wood is a sign","Contact licensed exterminator for persistent infestations"]
        case .structural: return ["Contact a licensed structural engineer for professional assessment","Do NOT attempt structural repairs without professional evaluation","Sticking doors/windows may indicate foundation movement","Document with dated photos for insurance purposes"]
        case .other: return ["Document the issue thoroughly with photos","Note date of first observation and any changes since","Consult appropriate professional based on issue type"]
        }
    }
    var icon: String {
        switch self { case .crack: return "hammer.fill"; case .leak: return "drop.triangle.fill"
        case .mold: return "allergens.fill"; case .dampness: return "humidity.fill"
        case .electrical: return "bolt.trianglebadge.exclamationmark.fill"; case .pest: return "ant.fill"
        case .structural: return "building.columns.fill"; case .other: return "questionmark.circle.fill" }
    }
}
