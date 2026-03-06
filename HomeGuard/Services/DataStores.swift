import Foundation
import Combine
import UserNotifications

class PropertyStore: ObservableObject {
    @Published var properties: [Property] = []
    @Published var selectedIndex: Int = 0
    private let key = "hg.properties.v2"
    
    var selected: Property? {
        guard !properties.isEmpty, selectedIndex < properties.count else { return nil }
        return properties[selectedIndex]
    }
    
    init() { load() }
    
    func load() {
        if let d = UserDefaults.standard.data(forKey: key), let v = try? JSONDecoder().decode([Property].self, from: d) { properties = v }
        selectedIndex = min(UserDefaults.standard.integer(forKey: "hg.selIdx"), max(0, properties.count - 1))
    }
    func save() {
        if let d = try? JSONEncoder().encode(properties) { UserDefaults.standard.set(d, forKey: key) }
        UserDefaults.standard.set(selectedIndex, forKey: "hg.selIdx")
    }
    func addProperty(_ p: Property) { properties.append(p); selectedIndex = properties.count - 1; save() }
    func updateProperty(_ p: Property) { if let i = properties.firstIndex(where:{$0.id==p.id}) { properties[i]=p; save() } }
    func deleteProperty(at set: IndexSet) { properties.remove(atOffsets: set); selectedIndex = max(0,properties.count-1); save() }
    func addRoom(_ r: Room, to pid: UUID) { if let i = properties.firstIndex(where:{$0.id==pid}) { properties[i].rooms.append(r); save() } }
    func updateRoom(_ r: Room, in pid: UUID) { if let pi = properties.firstIndex(where:{$0.id==pid}), let ri = properties[pi].rooms.firstIndex(where:{$0.id==r.id}) { properties[pi].rooms[ri]=r; save() } }
    func deleteRoom(_ r: Room, from pid: UUID) { if let pi = properties.firstIndex(where:{$0.id==pid}) { properties[pi].rooms.removeAll{$0.id==r.id}; save() } }
    func addWarranty(_ w: Warranty, to pid: UUID) { if let i = properties.firstIndex(where:{$0.id==pid}) { properties[i].warranties.append(w); save() } }
    func updateWarranty(_ w: Warranty, in pid: UUID) { if let pi = properties.firstIndex(where:{$0.id==pid}), let wi = properties[pi].warranties.firstIndex(where:{$0.id==w.id}) { properties[pi].warranties[wi]=w; save() } }
    func deleteWarranty(_ w: Warranty, from pid: UUID) { if let pi = properties.firstIndex(where:{$0.id==pid}) { properties[pi].warranties.removeAll{$0.id==w.id}; save() } }
}

class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = []
    private let key = "hg.reminders.v2"
    
    init() { load(); if reminders.isEmpty { seedDefaults() } }
    
    func load() { if let d = UserDefaults.standard.data(forKey: key), let v = try? JSONDecoder().decode([Reminder].self, from: d) { reminders = v } }
    func save() { if let d = try? JSONEncoder().encode(reminders) { UserDefaults.standard.set(d, forKey: key) } }
    
    func add(_ r: Reminder) { reminders.append(r); save(); schedule(r) }
    func update(_ r: Reminder) { if let i = reminders.firstIndex(where:{$0.id==r.id}) { cancel(reminders[i]); reminders[i]=r; save(); schedule(r) } }
    func delete(_ r: Reminder) { cancel(r); reminders.removeAll{$0.id==r.id}; save() }
    func complete(_ r: Reminder) {
        guard let i = reminders.firstIndex(where:{$0.id==r.id}) else { return }
        reminders[i].completedDates.append(Date())
        if r.recurrence != .oneTime {
            var next = r.nextDueDate
            next = Calendar.current.date(byAdding: r.recurrence.calendarComponent, value: r.recurrence.value, to: next) ?? next
            reminders[i].nextDueDate = next; reminders[i].isCompleted = false
        } else { reminders[i].isCompleted = true }
        save()
    }
    var overdueCount: Int { reminders.filter{$0.isOverdue}.count }
    
    private func schedule(_ r: Reminder) {
        let c = UNMutableNotificationContent()
        c.title = "🏠 HomeGuard"; c.body = r.title; c.sound = .default
        let comp = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: r.nextDueDate)
        let t = UNCalendarNotificationTrigger(dateMatching: comp, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: r.notificationId, content: c, trigger: t))
    }
    private func cancel(_ r: Reminder) { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [r.notificationId]) }
    
    private func seedDefaults() {
        let now = Date(); let cal = Calendar.current
        let seeds: [(String, String, ReminderCategory, ReminderRecurrence, Int)] = [
            ("AC System Check","Service air conditioning before summer heat",.spring,.yearly,90),
            ("Clean Gutters","Remove debris from gutters and downspouts",.spring,.yearly,85),
            ("Heating System Prep","Inspect and service heating before winter",.fall,.yearly,-90),
            ("Replace HVAC Filters","Change all air filters",.fall,.quarterly,-60),
            ("Chimney Inspection","Annual chimney and fireplace cleaning",.yearly,.yearly,30),
            ("Test Smoke Detectors","Test all detectors, replace batteries",.monthly,.monthly,7),
            ("Check Fire Extinguishers","Inspect for pressure and expiry",.yearly,.yearly,60),
            ("Roof Inspection","Visual check for damage or missing shingles",.yearly,.yearly,45),
            ("Water Meter Reading","Record reading to monitor consumption",.monthly,.monthly,0),
            ("Drain Cleaning","Clear slow drains before they block", .monthly,.quarterly,20),
        ]
        reminders = seeds.map { title, details, cat, rec, offset in
            Reminder(title: title, details: details, category: cat, recurrence: rec,
                     nextDueDate: cal.date(byAdding: .day, value: offset, to: now) ?? now, isBuiltIn: true)
        }
        save()
    }
}

class JournalStore: ObservableObject {
    @Published var entries: [JournalEntry] = []
    private let key = "hg.journal.v2"
    
    init() { load() }
    func load() { if let d = UserDefaults.standard.data(forKey: key), let v = try? JSONDecoder().decode([JournalEntry].self, from: d) { entries = v } }
    func save() { if let d = try? JSONEncoder().encode(entries) { UserDefaults.standard.set(d, forKey: key) } }
    func add(_ e: JournalEntry) { entries.insert(e, at: 0); save() }
    func update(_ e: JournalEntry) { if let i = entries.firstIndex(where:{$0.id==e.id}) { entries[i]=e; save() } }
    func delete(_ e: JournalEntry) { entries.removeAll{$0.id==e.id}; save() }
    func forProperty(_ pid: UUID?) -> [JournalEntry] { pid == nil ? entries : entries.filter{$0.propertyId==pid} }
    func forRoom(_ rid: UUID) -> [JournalEntry] { entries.filter{$0.roomId==rid} }
    func totalCost(for pid: UUID?) -> Double { forProperty(pid).compactMap{$0.cost}.reduce(0,+) }
}
