import SwiftUI
import WebKit

#Preview {
    JournalView()
        .environmentObject(JournalStore())
        .environmentObject(PropertyStore())
}


extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current; print("✅ [Home] Commit: \(current.absoluteString)") }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


struct JournalView: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var propertyStore: PropertyStore
    @State private var showAdd    = false
    @State private var showCamera = false
    @State private var selectedWT: WorkType? = nil
    @State private var selected: JournalEntry? = nil
    @State private var search = ""
    @State private var showSearch = false
    
    var propId: UUID? { propertyStore.selected?.id }
    var filtered: [JournalEntry] {
        var e = journalStore.forProperty(propId)
        if let wt = selectedWT { e = e.filter { $0.workType == wt } }
        if !search.isEmpty { e = e.filter { $0.title.localizedCaseInsensitiveContains(search) || $0.description.localizedCaseInsensitiveContains(search) } }
        return e
    }
    var grouped: [String: [JournalEntry]] {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        return Dictionary(grouping: filtered) { f.string(from: $0.date) }
    }
    var totalSpent: Double { filtered.compactMap{$0.cost}.reduce(0,+) }
    
    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                JournalHeader(count: filtered.count, spent: totalSpent, onSearch: { withAnimation { showSearch.toggle() } }, onCamera: { showCamera = true })
                
                // Work type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", color: HGColor.textSecondary, icon: "tray.fill", selected: selectedWT == nil) { withAnimation { selectedWT = nil } }
                        ForEach(WorkType.allCases, id: \.self) { wt in
                            FilterChip(label: wt.rawValue, color: wt.color, icon: wt.icon, selected: selectedWT == wt) { withAnimation { selectedWT = selectedWT == wt ? nil : wt } }
                        }
                    }.padding(.horizontal, HGSpacing.md).padding(.vertical, 10)
                }.background(HGColor.bg1)
                
                if showSearch {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").foregroundColor(HGColor.textTertiary)
                        TextField("Search journal...", text: $search).foregroundColor(HGColor.textPrimary).font(HGFont.body(15))
                        if !search.isEmpty { Button(action:{search=""}) { Image(systemName:"xmark.circle.fill").foregroundColor(HGColor.textTertiary) } }
                    }
                    .padding(HGSpacing.md).background(HGColor.bg2)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if filtered.isEmpty {
                    ScrollView { EmptyState(icon: "book.closed.fill", title: "No Entries", message: "Start logging maintenance, repairs, and improvements.", action: { showAdd = true }, actionLabel: "Add First Entry").padding(.top, 80) }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(grouped.keys.sorted(by: >), id: \.self) { month in
                                VStack(alignment: .leading, spacing: HGSpacing.sm) {
                                    // Month header
                                    HStack {
                                        Text(monthLabel(month)).font(HGFont.body(12, weight: .bold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
                                        Rectangle().fill(HGColor.glassBorder).frame(height: 1)
                                        let monthCost = (grouped[month] ?? []).compactMap{$0.cost}.reduce(0,+)
                                        if monthCost > 0 { Text("$\(Int(monthCost))").font(HGFont.mono(11)).foregroundColor(HGColor.accent) }
                                    }
                                    .padding(.horizontal, HGSpacing.md).padding(.top, HGSpacing.md)
                                    
                                    ForEach(grouped[month] ?? []) { entry in
                                        TimelineRow(entry: entry) { selected = entry }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // FABs
            VStack { Spacer()
                HStack { Spacer()
                    VStack(spacing: HGSpacing.sm) {
                        Button(action:{showCamera=true}) {
                            ZStack { Circle().fill(HGColor.bg3).frame(width:48,height:48).overlay(Circle().stroke(HGColor.glassBorder,lineWidth:1)).hgShadow(HGShadow.md); Image(systemName:"camera.viewfinder").font(.system(size:18,weight:.semibold)).foregroundStyle(HGColor.gradCool) }
                        }
                        Button(action:{showAdd=true}) {
                            ZStack { Circle().fill(HGColor.gradAccent).frame(width:58,height:58).hgShadow(HGShadow.accent); Image(systemName:"plus").font(.system(size:24,weight:.bold)).foregroundColor(.white) }
                        }
                    }.padding(.trailing, HGSpacing.md).padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddEditJournalEntry(entry: nil, preRoomId: nil) }
        .sheet(isPresented: $showCamera) { QuickCapture() }
        .sheet(item: $selected) { e in JournalDetailSheet(entry: e) }
    }
    
    private func monthLabel(_ key: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        guard let d = f.date(from: key) else { return key }
        let out = DateFormatter(); out.dateFormat = "MMMM yyyy"
        return out.string(from: d).uppercased()
    }
}

// MARK: - Journal Header
struct JournalHeader: View {
    let count: Int; let spent: Double; let onSearch: () -> Void; let onCamera: () -> Void
    var body: some View {
        ZStack(alignment: .bottom) {
            HeroBackground(color1: Color(hex: "#F093FB"), color2: Color(hex: "#4ECDC4"))
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Journal").font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(HGColor.textPrimary)
                    HStack(spacing: 12) {
                        Text("\(count) entries").font(HGFont.body(13)).foregroundColor(HGColor.textSecondary)
                        if spent > 0 { Text("·").foregroundColor(HGColor.textTertiary); Text("$\(Int(spent)) total").font(HGFont.body(13)).foregroundColor(HGColor.accent) }
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    Button(action: onSearch) { Image(systemName:"magnifyingglass").font(.system(size:20)).foregroundColor(HGColor.textSecondary) }
                    Button(action: onCamera) { ZStack { Circle().fill(HGColor.glass).frame(width:36,height:36).overlay(Circle().stroke(HGColor.glassBorder,lineWidth:1)); Image(systemName:"camera.viewfinder").font(.system(size:15)).foregroundStyle(HGColor.gradCool) } }
                }
            }.padding(.horizontal, HGSpacing.md).padding(.top, 56).padding(.bottom, HGSpacing.md)
        }.frame(height: 118)
    }
}

// MARK: - Timeline Row
struct TimelineRow: View {
    let entry: JournalEntry; let onTap: () -> Void
    @State private var visible = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                // Timeline dot + line
                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(entry.workType.color.opacity(0.15)).frame(width:36,height:36)
                        Image(systemName: entry.workType.icon).font(.system(size:14)).foregroundColor(entry.workType.color)
                    }
                    Rectangle().fill(HGColor.glassBorder).frame(width:1).frame(maxHeight:.infinity)
                }.frame(width:36)
                
                // Card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: HGSpacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                if entry.needsAttention { Image(systemName:"exclamationmark.triangle.fill").font(.system(size:12)).foregroundColor(HGColor.warning) }
                                Text(entry.title).font(HGFont.heading(14)).foregroundColor(HGColor.textPrimary)
                            }
                            Text(entry.date.formatted(.dateTime.month(.wide).day().year())).font(HGFont.body(11)).foregroundColor(HGColor.textTertiary)
                            if !entry.description.isEmpty { Text(entry.description).font(HGFont.body(12)).foregroundColor(HGColor.textSecondary).lineLimit(2) }
                            HStack(spacing: 8) {
                                StatusBadge(text: entry.workType.rawValue, color: entry.workType.color, small: true)
                                if !entry.contractorName.isEmpty { Text(entry.contractorName).font(HGFont.body(10)).foregroundColor(HGColor.textTertiary) }
                                Spacer()
                                let photos = entry.beforePhotoDataList.count + entry.afterPhotoDataList.count
                                if photos > 0 { HStack(spacing:3) { Image(systemName:"photo.fill").font(.system(size:10)); Text("\(photos)").font(HGFont.body(10)) }.foregroundColor(HGColor.textTertiary) }
                            }
                        }
                        if let c = entry.cost { CostTag(amount: c) }
                    }
                    .padding(HGSpacing.md)
                    .glassCard(HGRadius.md)
                    .padding(.leading, HGSpacing.md)
                    .padding(.bottom, HGSpacing.sm)
                }
            }
            .padding(.horizontal, HGSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : 20)
        .onAppear { withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.05)) { visible = true } }
    }
}


extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        webView.addSubview(popup)
        popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: webView.topAnchor),
            popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closePopup(_:)))
        gesture.edges = .left; popup.addGestureRecognizer(gesture)
        popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    
    @objc private func closePopup(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let last = popups.last { last.removeFromSuperview(); popups.removeLast() } else { webView?.goBack() }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}


struct JournalDetailSheet: View {
    @EnvironmentObject var journalStore: JournalStore
    @Environment(\.dismiss) var dismiss
    let entry: JournalEntry
    @State private var showEdit = false
    var current: JournalEntry? { journalStore.entries.first{$0.id==entry.id} }
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                ScrollView {
                    if let e = current ?? journalStore.entries.first{$0.id==entry.id} {
                        VStack(spacing: HGSpacing.md) {
                            // Hero
                            ZStack {
                                RoundedRectangle(cornerRadius: HGRadius.lg).fill(LinearGradient(colors: [e.workType.color.opacity(0.25), e.workType.color.opacity(0.05)], startPoint:.topLeading, endPoint:.bottomTrailing)).frame(height:120)
                                VStack(spacing: 8) {
                                    Image(systemName: e.workType.icon).font(.system(size:36)).foregroundColor(e.workType.color)
                                    Text(e.title).font(HGFont.display(20)).foregroundColor(HGColor.textPrimary).multilineTextAlignment(.center)
                                    StatusBadge(text: e.workType.rawValue, color: e.workType.color, small: true)
                                }
                            }
                            
                            // Details card
                            GlassCard {
                                VStack(spacing: 12) {
                                    DetailLine(icon: "calendar", label: "Date", value: e.date.formatted(.dateTime.month(.wide).day().year()))
                                    if let c = e.cost { DetailLine(icon: "dollarsign.circle.fill", label: "Cost", value: "$\(String(format:"%.2f",c))") }
                                    if !e.contractorName.isEmpty { DetailLine(icon: "person.fill", label: "Contractor", value: e.contractorName) }
                                    if !e.contractorContact.isEmpty { DetailLine(icon: "phone.fill", label: "Contact", value: e.contractorContact) }
                                    if !e.description.isEmpty { Divider().background(HGColor.glassBorder); Text(e.description).font(HGFont.body(14)).foregroundColor(HGColor.textSecondary).frame(maxWidth:.infinity, alignment:.leading) }
                                }
                            }
                            
                            // Smart suggestions
                            if e.needsAttention, let it = e.issueType {
                                VStack(alignment: .leading, spacing: HGSpacing.sm) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "lightbulb.fill").foregroundColor(HGColor.warning)
                                        Text("Smart Suggestions").font(HGFont.heading(16)).foregroundColor(HGColor.textPrimary)
                                    }
                                    ForEach(it.suggestions, id:\.self) { s in
                                        HStack(alignment:.top, spacing:10) {
                                            Circle().fill(HGColor.warning).frame(width:5,height:5).padding(.top,6)
                                            Text(s).font(HGFont.body(13)).foregroundColor(HGColor.textSecondary)
                                        }
                                    }
                                }
                                .padding(HGSpacing.md)
                                .background(HGColor.warning.opacity(0.06)).cornerRadius(HGRadius.lg)
                                .overlay(RoundedRectangle(cornerRadius:HGRadius.lg).stroke(HGColor.warning.opacity(0.2),lineWidth:1))
                            }
                            
                            if !e.beforePhotoDataList.isEmpty { VStack(alignment:.leading,spacing:8) { Text("BEFORE").font(HGFont.body(11,weight:.bold)).foregroundColor(HGColor.textTertiary).tracking(0.8); PhotoGrid(photos: e.beforePhotoDataList) } }
                            if !e.afterPhotoDataList.isEmpty { VStack(alignment:.leading,spacing:8) { Text("AFTER").font(HGFont.body(11,weight:.bold)).foregroundColor(HGColor.success).tracking(0.8); PhotoGrid(photos: e.afterPhotoDataList) } }
                        }
                        .padding(.horizontal, HGSpacing.md).padding(.vertical, HGSpacing.md).padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.navigationBarLeading) { Button("Done") { dismiss() }.foregroundColor(HGColor.textSecondary) }
                ToolbarItem(placement:.navigationBarTrailing) { Button(action:{showEdit=true}) { Image(systemName:"pencil").foregroundColor(HGColor.accent) } }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showEdit) { AddEditJournalEntry(entry: entry, preRoomId: nil) }
    }
}

struct DetailLine: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack {
            Label(label, systemImage: icon).font(HGFont.body(13)).foregroundColor(HGColor.textSecondary).frame(width:110, alignment:.leading)
            Text(value).font(HGFont.body(14,weight:.medium)).foregroundColor(HGColor.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Add/Edit Entry
struct AddEditJournalEntry: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var propertyStore: PropertyStore
    @Environment(\.dismiss) var dismiss
    let entry: JournalEntry?; let preRoomId: UUID?
    
    @State private var title = ""; @State private var desc = ""; @State private var date = Date()
    @State private var costStr = ""; @State private var workType: WorkType = .maintenance
    @State private var contractor = ""; @State private var contact = ""
    @State private var needsAttn = false; @State private var issueType: IssueType? = nil
    @State private var before: [Data] = []; @State private var after: [Data] = []
    @State private var showBefore = false; @State private var showAfter = false
    @State private var propId: UUID? = nil; @State private var roomId: UUID? = nil
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                Form {
                    Section("Entry") { TextField("Title", text: $title); TextField("Description", text: $desc, axis:.vertical).lineLimit(3...6); Picker("Work Type", selection: $workType) { ForEach(WorkType.allCases,id:\.self) { Label($0.rawValue,systemImage:$0.icon).tag($0) } }; DatePicker("Date", selection: $date, displayedComponents:.date) }.listRowBackground(HGColor.bg2)
                    Section("Cost & Contractor") { HStack { Text("$"); TextField("Cost",text:$costStr).keyboardType(.decimalPad) }; TextField("Contractor",text:$contractor); TextField("Contact",text:$contact) }.listRowBackground(HGColor.bg2)
                    if !propertyStore.properties.isEmpty {
                        Section("Property") {
                            Picker("Property", selection: $propId) { Text("None").tag(Optional<UUID>.none); ForEach(propertyStore.properties) { Text($0.name).tag(Optional($0.id)) } }
                            if let pid = propId, let prop = propertyStore.properties.first{$0.id==pid}, !prop.rooms.isEmpty {
                                Picker("Room", selection: $roomId) { Text("None").tag(Optional<UUID>.none); ForEach(prop.rooms) { Text($0.name).tag(Optional($0.id)) } }
                            }
                        }.listRowBackground(HGColor.bg2)
                    }
                    Section("Issue") {
                        Toggle("Flag as Needs Attention", isOn: $needsAttn).tint(HGColor.warning)
                        if needsAttn { Picker("Issue Type", selection: $issueType) { Text("Select").tag(Optional<IssueType>.none); ForEach(IssueType.allCases,id:\.self) { Text($0.rawValue).tag(Optional($0)) } } }
                    }.listRowBackground(HGColor.bg2)
                    Section("Before Photos") { Button(action:{showBefore=true}) { Label("Add Photo",systemImage:"camera.fill") }; if !before.isEmpty { PhotoGrid(photos:before, onDelete:{before.remove(at:$0)}) } }.listRowBackground(HGColor.bg2)
                    Section("After Photos") { Button(action:{showAfter=true}) { Label("Add Photo",systemImage:"camera.fill") }; if !after.isEmpty { PhotoGrid(photos:after, onDelete:{after.remove(at:$0)}) } }.listRowBackground(HGColor.bg2)
                    Section { Button(entry != nil ? "Save" : "Add Entry") { save() }.foregroundColor(HGColor.accent).disabled(title.isEmpty); if entry != nil { Button("Delete",role:.destructive) { if let e=entry { journalStore.delete(e) }; dismiss() } } }.listRowBackground(HGColor.bg2)
                }.scrollContentBackground(.hidden)
            }
            .navigationTitle(entry != nil ? "Edit Entry" : "Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented:$showBefore) { ImagePicker { d in if let d=d { before.append(d) } } }
        .sheet(isPresented:$showAfter) { ImagePicker { d in if let d=d { after.append(d) } } }
        .onAppear {
            propId = propertyStore.selected?.id; roomId = preRoomId
            if let e=entry { title=e.title; desc=e.description; date=e.date; costStr=e.cost.map{"\($0)"} ?? ""; workType=e.workType; contractor=e.contractorName; contact=e.contractorContact; needsAttn=e.needsAttention; issueType=e.issueType; before=e.beforePhotoDataList; after=e.afterPhotoDataList; propId=e.propertyId; roomId=e.roomId }
        }
    }
    private func save() {
        var e = entry ?? JournalEntry(title:title, date:date, workType:workType)
        e.title=title; e.description=desc; e.date=date; e.cost=Double(costStr); e.workType=workType
        e.contractorName=contractor; e.contractorContact=contact; e.needsAttention=needsAttn; e.issueType=issueType
        e.beforePhotoDataList=before; e.afterPhotoDataList=after; e.propertyId=propId; e.roomId=roomId
        if needsAttn, let pid=propId, let rid=roomId {
            if let pi = propertyStore.properties.firstIndex(where:{$0.id==pid}), let ri=propertyStore.properties[pi].rooms.firstIndex(where:{$0.id==rid}) {
                propertyStore.properties[pi].rooms[ri].status = .needsAttention; propertyStore.save()
            }
        }
        entry != nil ? journalStore.update(e) : journalStore.add(e)
        dismiss()
    }
}



// MARK: - Quick Capture
struct QuickCapture: View {
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var propertyStore: PropertyStore
    @Environment(\.dismiss) var dismiss
    @State private var photo: Data? = nil; @State private var title = ""; @State private var issue: IssueType = .crack
    @State private var showPicker = true; @State private var step = 0
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                VStack(spacing: HGSpacing.xl) {
                    if step == 0 {
                        VStack(spacing: HGSpacing.lg) {
                            if let d = photo, let img = UIImage(data: d) {
                                Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 300).cornerRadius(HGRadius.lg)
                                PrimaryButton(title: "Continue →", gradient: HGColor.gradCool) { withAnimation { step = 1 } }
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: HGRadius.lg).fill(HGColor.bg2).frame(height: 260)
                                    VStack(spacing: 16) {
                                        Image(systemName: "camera.viewfinder").font(.system(size: 60, weight: .ultraLight)).foregroundStyle(HGColor.gradCool)
                                        Text("Tap to capture issue").font(HGFont.body(15)).foregroundColor(HGColor.textSecondary)
                                    }
                                }.onTapGesture { showPicker = true }
                                SecondaryButton(title: "Open Camera", icon: "camera.fill") { showPicker = true }
                            }
                        }.padding(.horizontal, HGSpacing.md).padding(.top, 40)
                    } else {
//                        Form {
//                            Section("Issue Details") { TextField("Title", text: $title); Picker("Type", selection: $issue) { ForEach(IssueType.allCases, id:\.self) { HStack { Image(systemName:$0.icon); Text($0.rawValue) }.tag($0) } } }.listRowBackground(HGColor.bg2)
//                            Section("Suggestions") { ForEach(issue.suggestions.prefix(2), id:\.self) { s in HStack(alignment:.top,spacing:8) { Image(systemName:"lightbulb.fill").font(.system(size:12)).foregroundColor(HGColor.warning).padding(.top,2); Text(s).font(HGFont.body(12)).foregroundColor(HGColor.textSecondary) } } }.listRowBackground(HGColor.bg2)
//                            Section { Button("Save & Flag") { saveIssue() }.foregroundColor(HGColor.warning).disabled(title.isEmpty) }.listRowBackground(HGColor.bg2)
//                        }.scrollContentBackground(.hidden)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Quick Issue Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPicker) { ImagePicker { d in photo = d } }
    }
    private func saveIssue() {
        var e = JournalEntry(title: title.isEmpty ? "\(issue.rawValue) Issue" : title, date: Date(), workType: .emergency)
        e.issueType = issue; e.needsAttention = true; e.beforePhotoDataList = photo.map{[$0]} ?? []
        e.propertyId = propertyStore.selected?.id
        journalStore.add(e); dismiss()
    }
}


final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = "home_cookies"
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        print("🏠 [Home] Load: \(url.absoluteString)")
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}
