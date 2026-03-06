import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var reminderStore: ReminderStore
    @State private var selectedCat: ReminderCategory? = nil
    @State private var showAdd = false
    @State private var editing: Reminder? = nil
    
    var filtered: [Reminder] {
        let base = reminderStore.reminders
        if let c = selectedCat { return base.filter { $0.category == c } }
        return base
    }
    var overdue:  [Reminder] { filtered.filter { $0.isOverdue  }.sorted { $0.nextDueDate < $1.nextDueDate } }
    var upcoming: [Reminder] { filtered.filter { !$0.isOverdue }.sorted { $0.nextDueDate < $1.nextDueDate } }
    
    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()
            
            VStack(spacing: 0) {
                RemindersHeader(overdueCount: reminderStore.overdueCount)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", color: HGColor.textSecondary, icon: "tray.fill", selected: selectedCat == nil) { selectedCat = nil }
                        ForEach(ReminderCategory.allCases, id: \.self) { cat in
                            FilterChip(label: cat.rawValue, color: cat.color, icon: cat.icon, selected: selectedCat == cat) {
                                withAnimation { selectedCat = selectedCat == cat ? nil : cat }
                            }
                        }
                    }.padding(.horizontal, HGSpacing.md).padding(.vertical, 10)
                }
                .background(HGColor.bg1)
                
                if filtered.isEmpty {
                    ScrollView { EmptyState(icon: "bell.slash.fill", title: "No Reminders", message: "Add a reminder or use the built-in seasonal checklists.", action: { showAdd = true }, actionLabel: "Add Reminder").padding(.top, 80) }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HGSpacing.lg) {
                            if !overdue.isEmpty {
                                VStack(spacing: HGSpacing.sm) {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 13)).foregroundColor(HGColor.danger)
                                            Text("OVERDUE").font(HGFont.body(12, weight: .bold)).foregroundColor(HGColor.danger).tracking(0.8)
                                        }
                                        Spacer()
                                        Text("\(overdue.count)").font(HGFont.mono(12)).foregroundColor(HGColor.textTertiary)
                                    }
                                    ForEach(overdue) { r in
                                        ReminderCard(reminder: r, onComplete: { reminderStore.complete(r) }, onTap: { editing = r })
                                    }
                                }
                            }
                            
                            if !upcoming.isEmpty {
                                VStack(spacing: HGSpacing.sm) {
                                    HStack {
                                        Text("UPCOMING").font(HGFont.body(12, weight: .bold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
                                        Spacer()
                                        Text("\(upcoming.count)").font(HGFont.mono(12)).foregroundColor(HGColor.textTertiary)
                                    }
                                    ForEach(upcoming) { r in
                                        ReminderCard(reminder: r, onComplete: { reminderStore.complete(r) }, onTap: { editing = r })
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, HGSpacing.md)
                        .padding(.vertical, HGSpacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // FAB
            VStack { Spacer()
                HStack { Spacer()
                    Button(action: { showAdd = true }) {
                        ZStack { Circle().fill(HGColor.gradAccent).frame(width:58,height:58).hgShadow(HGShadow.accent); Image(systemName:"plus").font(.system(size:24,weight:.bold)).foregroundColor(.white) }
                    }.padding(.trailing, HGSpacing.md).padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddEditReminderSheet(reminder: nil) }
        .sheet(item: $editing) { r in AddEditReminderSheet(reminder: r) }
    }
}

struct RemindersHeader: View {
    let overdueCount: Int
    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                HeroBackground(color1: overdueCount > 0 ? HGColor.danger : HGColor.accent, color2: Color(hex: "#4ECDC4"))
                    .frame(width: geo.size.width)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminders").font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(HGColor.textPrimary)
                    HStack(spacing: 6) {
                        if overdueCount > 0 {
                            PulseDot(color: HGColor.danger, size: 8)
                            Text("\(overdueCount) overdue").font(HGFont.body(13)).foregroundColor(HGColor.danger)
                        } else {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundColor(HGColor.success)
                            Text("All up to date").font(HGFont.body(13)).foregroundColor(HGColor.success)
                        }
                    }
                }
                Spacer()
                if overdueCount > 0 {
                    ZStack { Circle().fill(HGColor.danger).frame(width:42,height:42).hgShadow(HGShadow.danger); Text("\(overdueCount)").font(HGFont.heading(16)).foregroundColor(.white) }
                }
            }
            .padding(.horizontal, HGSpacing.md).padding(.top, 56).padding(.bottom, HGSpacing.md)
        }.frame(height: 118)
    }
}

struct FilterChip: View {
    let label: String; let color: Color; var icon: String = ""; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if !icon.isEmpty { Image(systemName: icon).font(.system(size: 11)) }
                Text(label).font(HGFont.body(12, weight: selected ? .bold : .regular))
            }
            .foregroundColor(selected ? HGColor.bg0 : color)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(selected ? color : color.opacity(0.1))
            .cornerRadius(HGRadius.round)
            .overlay(Capsule().stroke(selected ? Color.clear : color.opacity(0.2), lineWidth: 0.5))
        }.buttonStyle(PlainButtonStyle())
    }
}

struct ReminderCard: View {
    let reminder: Reminder; let onComplete: () -> Void; let onTap: () -> Void
    @State private var checked = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left color bar
                Rectangle().fill(reminder.urgency.color).frame(width: 4).cornerRadius(2)
                
                HStack(spacing: HGSpacing.md) {
                    // Category icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(reminder.category.color.opacity(0.12)).frame(width:44,height:44)
                        Image(systemName: reminder.category.icon).font(.system(size:18)).foregroundColor(reminder.category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(reminder.title).font(HGFont.heading(14)).foregroundColor(HGColor.textPrimary).strikethrough(checked)
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill").font(.system(size: 10)).foregroundColor(reminder.urgency.color)
                            Text(reminder.isOverdue ? "Overdue \(abs(reminder.daysUntilDue))d" :
                                 reminder.daysUntilDue == 0 ? "Due today" : "In \(reminder.daysUntilDue)d")
                                .font(HGFont.body(11)).foregroundColor(reminder.urgency.color)
                            Text("·").foregroundColor(HGColor.textTertiary)
                            Text(reminder.recurrence.rawValue).font(HGFont.body(11)).foregroundColor(HGColor.textTertiary)
                        }
                        if !reminder.details.isEmpty {
                            Text(reminder.details).font(HGFont.body(11)).foregroundColor(HGColor.textSecondary).lineLimit(1)
                        }
                    }
                    Spacer()
                    
                    // Check button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { checked = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onComplete() }
                    }) {
                        ZStack {
                            Circle().stroke(reminder.urgency.color.opacity(0.4), lineWidth: 2).frame(width:32,height:32)
                            if checked { Circle().fill(HGColor.success).frame(width:32,height:32); Image(systemName:"checkmark").font(.system(size:13,weight:.bold)).foregroundColor(.white) }
                        }
                    }.buttonStyle(PlainButtonStyle())
                }
                .padding(HGSpacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: HGRadius.md)
                    .fill(LinearGradient(colors: [HGColor.bg3, HGColor.bg2], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.glassBorder, lineWidth: 1))
            )
            .hgShadow(HGShadow.sm)
            .cornerRadius(HGRadius.md)
            .clipped()
        }.buttonStyle(PlainButtonStyle())
    }
}

struct AddEditReminderSheet: View {
    @EnvironmentObject var reminderStore: ReminderStore
    @Environment(\.dismiss) var dismiss
    let reminder: Reminder?
    @State private var title = ""; @State private var details = ""
    @State private var category: ReminderCategory = .custom; @State private var recurrence: ReminderRecurrence = .yearly
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                Form {
                    Section("Details") { TextField("Title", text: $title); TextField("Description", text: $details) }.listRowBackground(HGColor.bg2)
                    Section("Category") { Picker("Category", selection: $category) { ForEach(ReminderCategory.allCases, id:\.self) { Label($0.rawValue, systemImage: $0.icon).tag($0) } } }.listRowBackground(HGColor.bg2)
                    Section("Schedule") {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        Picker("Repeat", selection: $recurrence) { ForEach(ReminderRecurrence.allCases, id:\.self) { Text($0.rawValue).tag($0) } }
                    }.listRowBackground(HGColor.bg2)
                    Section {
                        Button(reminder != nil ? "Save Changes" : "Add Reminder") { save() }.foregroundColor(HGColor.accent).disabled(title.isEmpty)
                        if reminder != nil { Button("Delete", role:.destructive) { if let r=reminder { reminderStore.delete(r) }; dismiss() } }
                    }.listRowBackground(HGColor.bg2)
                }.scrollContentBackground(.hidden)
            }
            .navigationTitle(reminder != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
            .preferredColorScheme(.dark)
        }
        .onAppear { if let r=reminder { title=r.title; details=r.details; category=r.category; recurrence=r.recurrence; dueDate=r.nextDueDate } }
    }
    private func save() {
        var r = reminder ?? Reminder(title:title, category:category, recurrence:recurrence, nextDueDate:dueDate)
        r.title=title; r.details=details; r.category=category; r.recurrence=recurrence; r.nextDueDate=dueDate
        reminder != nil ? reminderStore.update(r) : reminderStore.add(r)
        dismiss()
    }
}
