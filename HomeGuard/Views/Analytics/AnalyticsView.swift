import SwiftUI

#Preview {
    HomeNotificationView(store: Store())
}

struct AnalyticsView: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @EnvironmentObject var journalStore:  JournalStore
    @EnvironmentObject var reminderStore: ReminderStore

    @State private var selectedPeriod: AnalyticsPeriod = .year
    @State private var appeared = false

    var prop: Property? { propertyStore.selected }
    var entries: [JournalEntry] { journalStore.forProperty(prop?.id) }

    var filteredEntries: [JournalEntry] {
        let cutoff = selectedPeriod.cutoffDate
        return entries.filter { $0.date >= cutoff }
    }

    // MARK: - Computed analytics
    var totalSpent: Double { filteredEntries.compactMap { $0.cost }.reduce(0, +) }
    var entryCount: Int { filteredEntries.count }
    var avgCostPerEntry: Double { entryCount > 0 ? totalSpent / Double(entryCount) : 0 }
    var healthScore: Int { computeHealthScore() }

    var spendingByMonth: [(String, Double)] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "MMM"
        var map: [Date: Double] = [:]
        for e in filteredEntries {
            let start = cal.startOfMonth(for: e.date)
            map[start, default: 0] += e.cost ?? 0
        }
        return map.sorted { $0.key < $1.key }.map { (fmt.string(from: $0.key), $0.value) }
    }

    var spendingByCategory: [(WorkType, Double)] {
        var map: [WorkType: Double] = [:]
        for e in filteredEntries { map[e.workType, default: 0] += e.cost ?? 0 }
        return map.sorted { $0.value > $1.value }
    }

    var issuesByType: [(IssueType, Int)] {
        var map: [IssueType: Int] = [:]
        for e in filteredEntries where e.issueType != nil { map[e.issueType!, default: 0] += 1 }
        return map.sorted { $0.value > $1.value }
    }

    var roomSpending: [(String, Double)] {
        var map: [String: Double] = [:]
        for e in filteredEntries {
            let name = prop?.rooms.first(where: { $0.id == e.roomId })?.name ?? "General"
            map[name, default: 0] += e.cost ?? 0
        }
        return map.sorted { $0.value > $1.value }.prefix(6).map { ($0.key, $0.value) }
    }

    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: HGSpacing.lg) {
                    AnalyticsHeader(healthScore: healthScore)

                    // Period selector
                    HStack(spacing: 8) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { p in
                            Button(action: { withAnimation(.spring(response: 0.3)) { selectedPeriod = p } }) {
                                Text(p.label)
                                    .font(HGFont.body(13, weight: selectedPeriod == p ? .bold : .regular))
                                    .foregroundColor(selectedPeriod == p ? HGColor.bg0 : HGColor.textSecondary)
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(selectedPeriod == p ? HGColor.accent : HGColor.bg2)
                                    .cornerRadius(HGRadius.md)
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, HGSpacing.md)

                    // KPI row
                    KPIRow(total: totalSpent, count: entryCount, avg: avgCostPerEntry)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Health score card
                    HealthScoreCard(score: healthScore, property: prop, reminders: reminderStore.reminders)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Spending over time chart
                    if !spendingByMonth.isEmpty {
                        SpendingBarChart(data: spendingByMonth, title: "Monthly Spending")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                    }

                    // Spending by category
                    if !spendingByCategory.isEmpty {
                        CategoryDonutChart(data: spendingByCategory)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                    }

                    // Room spending breakdown
                    if !roomSpending.isEmpty {
                        RoomSpendingChart(data: roomSpending)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                    }

                    // Issues breakdown
                    if !issuesByType.isEmpty {
                        IssuesBreakdown(data: issuesByType)
                    }

                    // Activity heatmap
                    ActivityHeatmap(entries: filteredEntries)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 60)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) { appeared = true }
        }
    }

    private func computeHealthScore() -> Int {
        var score = 100
        // Overdue reminders penalize
        let overdueCount = reminderStore.reminders.filter { $0.isOverdue }.count
        score -= min(overdueCount * 8, 40)
        // Rooms needing attention
        let needsAttn = prop?.rooms.filter { $0.status == .needsAttention }.count ?? 0
        score -= min(needsAttn * 10, 30)
        // Expired warranties
        let expiredW = prop?.warranties.filter { $0.status == .expired }.count ?? 0
        score -= min(expiredW * 5, 20)
        // Recent maintenance is good
        let recentEntries = entries.filter { $0.date > Calendar.current.date(byAdding: .month, value: -3, to: Date())! }.count
        score += min(recentEntries * 3, 15)
        return max(0, min(100, score))
    }
}

enum AnalyticsPeriod: CaseIterable {
    case threeMonths, sixMonths, year, allTime
    var label: String {
        switch self { case .threeMonths: return "3M"; case .sixMonths: return "6M"; case .year: return "1Y"; case .allTime: return "All" }
    }
    var cutoffDate: Date {
        let cal = Calendar.current
        switch self {
        case .threeMonths: return cal.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .sixMonths:   return cal.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .year:        return cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .allTime:     return Date(timeIntervalSince1970: 0)
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

// MARK: - Analytics Header
struct AnalyticsHeader: View {
    let healthScore: Int
    var body: some View {
        ZStack(alignment: .bottom) {
            HeroBackground(color1: Color(hex: "#23D18B"), color2: Color(hex: "#F5A623"))
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#23D18B"))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: "#23D18B").opacity(0.12)).cornerRadius(HGRadius.round)
                        Text("ANALYTICS").font(HGFont.body(11, weight: .bold))
                            .foregroundColor(Color(hex: "#23D18B")).tracking(1.2)
                    }
                    Text("Home Insights")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(HGColor.textPrimary)
                    Text("Track spending, health & maintenance trends")
                        .font(HGFont.body(13)).foregroundColor(HGColor.textSecondary)
                }
                Spacer()
                // Score ring
                ZStack {
                    Circle().stroke(HGColor.textMuted, lineWidth: 4).frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: CGFloat(healthScore) / 100)
                        .stroke(scoreColor(healthScore), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: scoreColor(healthScore).opacity(0.5), radius: 6)
                    VStack(spacing: 0) {
                        Text("\(healthScore)").font(HGFont.mono(15)).foregroundColor(scoreColor(healthScore))
                        Text("HP").font(HGFont.body(8, weight: .bold)).foregroundColor(HGColor.textTertiary)
                    }
                }
            }
            .padding(.horizontal, HGSpacing.md).padding(.top, 56).padding(.bottom, HGSpacing.md)
        }.frame(height: 130)
    }
    func scoreColor(_ s: Int) -> Color {
        s >= 80 ? HGColor.success : s >= 60 ? HGColor.warning : HGColor.danger
    }
}

// MARK: - KPI Row
struct KPIRow: View {
    let total: Double; let count: Int; let avg: Double
    var body: some View {
        HStack(spacing: HGSpacing.sm) {
            KPITile(value: "$\(Int(total))", label: "Total Spent", color: HGColor.accent, icon: "dollarsign.circle.fill")
            KPITile(value: "\(count)", label: "Entries", color: Color(hex: "#4ECDC4"), icon: "wrench.and.screwdriver.fill")
            KPITile(value: "$\(Int(avg))", label: "Avg Cost", color: Color(hex: "#F093FB"), icon: "chart.line.uptrend.xyaxis")
        }
        .padding(.horizontal, HGSpacing.md)
    }
}

struct KPITile: View {
    let value: String; let label: String; let color: Color; let icon: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 6)
            Text(value).font(HGFont.mono(20)).foregroundColor(HGColor.textPrimary)
                .shadow(color: color.opacity(0.25), radius: 8)
            Text(label).font(HGFont.body(10)).foregroundColor(HGColor.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, HGSpacing.md).glassCard()
    }
}

// MARK: - Health Score Card
struct HealthScoreCard: View {
    let score: Int
    let property: Property?
    let reminders: [Reminder]
    @State private var animate = false

    var scoreColor: Color { score >= 80 ? HGColor.success : score >= 60 ? HGColor.warning : HGColor.danger }
    var scoreLabel: String { score >= 80 ? "Excellent" : score >= 60 ? "Good" : score >= 40 ? "Needs Work" : "Critical" }

    var body: some View {
        VStack(spacing: HGSpacing.md) {
            HStack {
                Text("Home Health Score")
                    .font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                Spacer()
                StatusBadge(text: scoreLabel, color: scoreColor, small: true)
            }

            // Big score bar
            VStack(spacing: 8) {
                HStack {
                    Text("\(score)").font(HGFont.mono(44)).foregroundColor(scoreColor)
                        .shadow(color: scoreColor.opacity(0.4), radius: 12)
                    Text("/ 100").font(HGFont.body(18)).foregroundColor(HGColor.textTertiary).offset(y: 10)
                    Spacer()
                }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(HGColor.textMuted).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [scoreColor, scoreColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: animate ? UIScreen.main.bounds.width * 0.75 * CGFloat(score) / 100 : 0, height: 8)
                        .shadow(color: scoreColor.opacity(0.5), radius: 6)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animate)
            }

            // Score factors
            let factors = scoreFactors()
            if !factors.isEmpty {
                Divider().background(HGColor.glassBorder)
                VStack(spacing: 8) {
                    ForEach(factors, id: \.label) { f in
                        HStack(spacing: 10) {
                            Image(systemName: f.positive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(f.positive ? HGColor.success : HGColor.warning)
                            Text(f.label).font(HGFont.body(13)).foregroundColor(HGColor.textSecondary)
                            Spacer()
                            Text(f.positive ? "+\(f.points)" : "\(f.points)")
                                .font(HGFont.mono(12))
                                .foregroundColor(f.positive ? HGColor.success : HGColor.danger)
                        }
                    }
                }
            }
        }
        .padding(HGSpacing.md).glassCard()
        .padding(.horizontal, HGSpacing.md)
        .onAppear { animate = true }
    }

    func scoreFactors() -> [(label: String, points: Int, positive: Bool)] {
        var factors: [(String, Int, Bool)] = []
        let overdueCount = reminders.filter { $0.isOverdue }.count
        if overdueCount > 0 { factors.append(("\(overdueCount) overdue reminder\(overdueCount > 1 ? "s" : "")", -overdueCount * 8, false)) }
        let attnRooms = property?.rooms.filter { $0.status == .needsAttention }.count ?? 0
        if attnRooms > 0 { factors.append(("\(attnRooms) room\(attnRooms > 1 ? "s" : "") need attention", -attnRooms * 10, false)) }
        let expiredW = property?.warranties.filter { $0.status == .expired }.count ?? 0
        if expiredW > 0 { factors.append(("\(expiredW) expired warrant\(expiredW > 1 ? "ies" : "y")", -expiredW * 5, false)) }
        let goodRooms = property?.rooms.filter { $0.status == .allGood }.count ?? 0
        if goodRooms > 0 { factors.append(("\(goodRooms) rooms in good condition", goodRooms * 2, true)) }
        return factors
    }
}

// MARK: - Bar Chart
struct SpendingBarChart: View {
    let data: [(String, Double)]
    let title: String
    @State private var appeared = false

    var maxValue: Double { data.map { $0.1 }.max() ?? 1 }

    var body: some View {
        VStack(spacing: HGSpacing.md) {
            HStack {
                Text(title).font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                Spacer()
                Text("$\(Int(data.map { $0.1 }.reduce(0, +)))").font(HGFont.mono(14)).foregroundColor(HGColor.accent)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data, id: \.0) { month, value in
                    VStack(spacing: 4) {
                        Text("$\(Int(value))")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(HGColor.textTertiary)
                            .opacity(value > 0 ? 1 : 0)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [HGColor.accent, HGColor.accentWarm],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(
                                width: max(12, (UIScreen.main.bounds.width - 80) / CGFloat(data.count) - 8),
                                height: appeared ? max(4, 120 * CGFloat(value / maxValue)) : 4
                            )
                            .shadow(color: HGColor.glowAccent, radius: appeared ? 6 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05 * Double(data.firstIndex(where: { $0.0 == month }) ?? 0)), value: appeared)

                        Text(month)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(HGColor.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
        }
        .padding(HGSpacing.md).glassCard()
        .padding(.horizontal, HGSpacing.md)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appeared = true } }
    }
}

// MARK: - Category Donut Chart
struct CategoryDonutChart: View {
    let data: [(WorkType, Double)]
    @State private var selected: WorkType? = nil
    @State private var appeared = false

    var total: Double { data.map { $0.1 }.reduce(0, +) }

    var slices: [(WorkType, Double, Double, Double)] {
        var start = 0.0
        return data.map { wt, val in
            let pct = val / total
            let slice = (wt, start, start + pct, pct)
            start += pct
            return slice
        }
    }

    var body: some View {
        VStack(spacing: HGSpacing.md) {
            HStack {
                Text("Spending by Type")
                    .font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                Spacer()
            }

            HStack(spacing: HGSpacing.lg) {
                // Donut
                ZStack {
                    ForEach(slices, id: \.0) { wt, start, end, pct in
                        DonutSlice(
                            startAngle: .degrees(start * 360 - 90),
                            endAngle: .degrees(end * 360 - 90),
                            color: wt.color,
                            isSelected: selected == wt
                        )
                        .scaleEffect(appeared ? 1 : 0.1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(start * 0.5), value: appeared)
                        .onTapGesture { withAnimation { selected = selected == wt ? nil : wt } }
                    }

                    // Center
                    VStack(spacing: 2) {
                        if let sel = selected, let item = data.first(where: { $0.0 == sel }) {
                            Text("$\(Int(item.1))").font(HGFont.mono(16)).foregroundColor(item.0.color)
                            Text(item.0.rawValue).font(HGFont.body(9)).foregroundColor(HGColor.textTertiary).lineLimit(1)
                        } else {
                            Text("$\(Int(total))").font(HGFont.mono(16)).foregroundColor(HGColor.textPrimary)
                            Text("Total").font(HGFont.body(9)).foregroundColor(HGColor.textTertiary)
                        }
                    }
                }
                .frame(width: 130, height: 130)

                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data.prefix(6), id: \.0) { wt, val in
                        HStack(spacing: 8) {
                            Circle().fill(wt.color).frame(width: 8, height: 8)
                                .shadow(color: wt.color.opacity(0.5), radius: 3)
                            Text(wt.rawValue).font(HGFont.body(12)).foregroundColor(HGColor.textSecondary)
                            Spacer()
                            Text("\(Int(val / total * 100))%").font(HGFont.mono(11)).foregroundColor(HGColor.textTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(HGSpacing.md).glassCard()
        .padding(.horizontal, HGSpacing.md)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { appeared = true } }
    }
}

struct DonutSlice: View {
    
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geo in
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = min(geo.size.width, geo.size.height) / 2
            let inner = r * 0.55
            Path { p in
                p.move(to: CGPoint(
                             x: c.x + inner * CGFloat(cos(startAngle.radians)),
                             y: c.y + inner * CGFloat(sin(startAngle.radians))
                         ))
                p.addArc(center: c, radius: inner, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                p.addLine(to: CGPoint(
                             x: c.x + r * CGFloat(cos(endAngle.radians)),
                             y: c.y + r * CGFloat(sin(endAngle.radians))
                         ))
                p.addArc(center: c, radius: r, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                p.closeSubpath()
            }
            .fill(color.opacity(isSelected ? 1.0 : 0.8))
            // .shadow(color: isSelected ? color.opacity(0.5) : .clear, radius: 8)
        }
    }
}

struct RoomSpendingChart: View {
    let data: [(String, Double)]
    var maxVal: Double { data.map { $0.1 }.max() ?? 1 }
    @State private var appeared = false

    var body: some View {
        VStack(spacing: HGSpacing.md) {
            HStack {
                Text("Spending by Room")
                    .font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                Spacer()
            }
            VStack(spacing: 10) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 10) {
                        Text(item.0)
                            .font(HGFont.body(12)).foregroundColor(HGColor.textSecondary)
                            .frame(width: 80, alignment: .leading).lineLimit(1)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(HGColor.textMuted).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: appeared ? max(8, 160 * CGFloat(item.1 / maxVal)) : 0, height: 8)
                                .shadow(color: Color(hex: "#4ECDC4").opacity(0.4), radius: appeared ? 4 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(i) * 0.08), value: appeared)
                        }
                        Text("$\(Int(item.1))")
                            .font(HGFont.mono(11)).foregroundColor(HGColor.textTertiary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }
            }
        }
        .padding(HGSpacing.md).glassCard()
        .padding(.horizontal, HGSpacing.md)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { appeared = true } }
    }
}

struct IssuesBreakdown: View {
    let data: [(IssueType, Int)]
    var body: some View {
        VStack(spacing: HGSpacing.md) {
            HStack {
                Text("Issues Logged").font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                Spacer()
                Text("\(data.map { $0.1 }.reduce(0, +)) total").font(HGFont.mono(12)).foregroundColor(HGColor.textTertiary)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(data, id: \.0) { issue, count in
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(HGColor.warning.opacity(0.1)).frame(width: 36, height: 36)
                            Image(systemName: issue.icon).font(.system(size: 15)).foregroundColor(HGColor.warning)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(count)").font(HGFont.mono(18)).foregroundColor(HGColor.textPrimary)
                            Text(issue.rawValue).font(HGFont.body(10)).foregroundColor(HGColor.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(10).glassCard(HGRadius.md)
                }
            }
        }
        .padding(HGSpacing.md).glassCard()
        .padding(.horizontal, HGSpacing.md)
    }
}

struct ActivityHeatmap: View {
    let entries: [JournalEntry]
    private let weeks = 12
    private let days  = 7

    var activityMap: [String: Int] {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        var map: [String: Int] = [:]
        for e in entries { map[fmt.string(from: e.date), default: 0] += 1 }
        return map
    }
    
    private var fmt: DateFormatter {
        var f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
    
    private var mFmt: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }

    var body: some View {
        VStack(spacing: HGSpacing.md) {
            HStack {
                Text("Activity Heatmap")
                    .font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                Spacer()
                Text("Last 12 weeks").font(HGFont.body(11)).foregroundColor(HGColor.textTertiary)
            }

            let cal = Calendar.current
            let today = Date()
            let dayLetters = ["S","M","T","W","T","F","S"]

            HStack(spacing: 0) {
                // Day labels
                VStack(spacing: 3) {
                    Spacer().frame(height: 14)
                    ForEach(0..<days, id: \.self) { d in
                        Text(dayLetters[d])
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(HGColor.textTertiary)
                            .frame(height: 13)
                    }
                }.frame(width: 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(0..<weeks, id: \.self) { w in
                            VStack(spacing: 0) {
                                // Month label for first day
                                let wDate = cal.date(byAdding: .weekOfYear, value: w - weeks + 1, to: today) ?? today
                                
                                Text(cal.component(.weekOfMonth, from: wDate) == 1 ? mFmt.string(from: wDate) : "")
                                    .font(.system(size: 9, weight: .medium)).foregroundColor(HGColor.textTertiary)
                                    .frame(height: 14)

                                VStack(spacing: 3) {
                                    ForEach(0..<days, id: \.self) { d in
                                        let date = cal.date(byAdding: .day, value: d - cal.component(.weekday, from: wDate) + 1, to: wDate) ?? wDate
                                        let key = fmt.string(from: date)
                                        let count = activityMap[key] ?? 0
                                        let isFuture = date > today

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(isFuture ? Color.clear : heatColor(count))
                                            .frame(width: 13, height: 13)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .stroke(isFuture ? Color.clear : (count == 0 ? HGColor.glassBorder : Color.clear), lineWidth: 0.5)
                                            )
                                    }
                                }
                            }
                            .frame(width: 13)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Legend
            HStack(spacing: 6) {
                Text("Less").font(.system(size: 9)).foregroundColor(HGColor.textTertiary)
                ForEach([0, 1, 2, 3, 4], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2).fill(heatColor(level)).frame(width: 12, height: 12)
                }
                Text("More").font(.system(size: 9)).foregroundColor(HGColor.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(HGSpacing.md).glassCard()
        .padding(.horizontal, HGSpacing.md)
    }

    func heatColor(_ count: Int) -> Color {
        switch count {
        case 0: return HGColor.bg3
        case 1: return HGColor.success.opacity(0.3)
        case 2: return HGColor.success.opacity(0.55)
        case 3: return HGColor.success.opacity(0.75)
        default: return HGColor.success
        }
    }
}

struct HomeNotificationView: View {
    @ObservedObject var store: Store
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "push_frame_land" : "push_frame")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.7)
                
                VStack(spacing: 18) {
                    Spacer(); titleText
                        .multilineTextAlignment(.center); subtitleText
                        .multilineTextAlignment(.center); actionButtons
                }.padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 32)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { store.dispatch(.permissionRequested) } label: {
                ZStack {
                    Text("Yes, I Want Bonuses!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            Color(hex: "8800FF")
                        )
                        .cornerRadius(10)
                }
                .frame(height: 55)
            }
            Button { store.dispatch(.permissionDeferred) } label: {
                Text("Skip").font(.headline).foregroundColor(.gray)
            }
        }.padding(.horizontal, 24)
    }
}

