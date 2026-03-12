import SwiftUI
import WebKit

struct MyHomeView: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @EnvironmentObject var journalStore:  JournalStore
    @State private var showAddProp   = false
    @State private var showEditProp  = false
    @State private var showAddRoom   = false
    @State private var showAddWarranty = false
    @State private var showAllWarranties = false
    @State private var showMap       = false
    
    var prop: Property? { propertyStore.selected }
    
    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()
            
            VStack(spacing: 0) {
             
              
                MyHomeHeader(
                    properties: propertyStore.properties,
                    selectedIndex: $propertyStore.selectedIndex,
                    onAdd: { showAddProp = true }
                )
            
                
                if propertyStore.properties.isEmpty {
                    ScrollView { EmptyState(icon: "house.and.flag.fill", title: "No Property Yet", message: "Create your home's digital passport to track everything.", action: { showAddProp = true }, actionLabel: "Add First Property").padding(.top, 80) }
                } else if let p = prop {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HGSpacing.lg) {
                            PassportCard(property: p, onEdit: { showEditProp = true })
                            
                            // Stats row
                            HStack(spacing: HGSpacing.sm) {
                                GlowNumber(value: "\(p.rooms.count)", label: "Rooms")
                                GlowNumber(value: "\(p.warranties.count)", label: "Warranties", color: HGColor.success)
                                GlowNumber(value: "$\(Int(journalStore.totalCost(for: p.id)))", label: "Total Spent", color: Color(hex: "#F093FB"))
                            }
                            
                            // Warranties
                            WarrantySection(property: p, onAdd: { showAddWarranty = true })
                            
                            // Rooms
                            RoomsGrid(property: p, onAdd: { showAddRoom = true })
                        }
                        .padding(.horizontal, HGSpacing.md)
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !propertyStore.properties.isEmpty {
                        Menu {
                            Button(action: { showAddRoom = true }) { Label("Add Room", systemImage: "plus.square.fill") }
                            Button(action: { showAddWarranty = true }) { Label("Add Warranty", systemImage: "shield.fill") }
                            Button(action: { showEditProp = true }) { Label("Edit Property", systemImage: "pencil") }
                            Button(action: { showMap = true }) { Label("Floor Plan", systemImage: "map.fill") }
                        } label: {
                            ZStack {
                                Circle().fill(HGColor.gradAccent).frame(width: 58, height: 58).hgShadow(HGShadow.accent)
                                Image(systemName: "plus").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, HGSpacing.md).padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddProp) { AddEditPropertySheet(property: nil) }
        .sheet(isPresented: $showEditProp) { if let p = prop { AddEditPropertySheet(property: p) } }
        .sheet(isPresented: $showAddRoom) { if let p = prop { AddEditRoomSheet(propertyId: p.id, room: nil) } }
        .sheet(isPresented: $showAddWarranty) { if let p = prop { AddEditWarrantySheet(propertyId: p.id, warranty: nil) } }
        .sheet(isPresented: $showMap) { RoomMapView() }
    }
}

// MARK: - Header
struct MyHomeHeader: View {
    let properties: [Property]; @Binding var selectedIndex: Int; let onAdd: () -> Void
    var body: some View {
        ZStack(alignment: .bottom) {
            HeroBackground()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Home").font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(HGColor.textPrimary)
                        Text("Home Passport").font(HGFont.body(13)).foregroundColor(HGColor.textSecondary)
                    }
                    Spacer()
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundStyle(HGColor.gradAccent)
                    }
                }
                .padding(.horizontal, HGSpacing.md).padding(.top, 56)
                
                if properties.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<properties.count, id: \.self) { i in
                                Button(action: { withAnimation(.spring(response: 0.3)) { selectedIndex = i } }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: properties[i].type.icon).font(.system(size: 11))
                                        Text(properties[i].name).font(HGFont.body(13, weight: selectedIndex == i ? .bold : .regular))
                                    }
                                    .foregroundColor(selectedIndex == i ? HGColor.bg0 : HGColor.textSecondary)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedIndex == i ? HGColor.gradAccent : LinearGradient(colors: [HGColor.glass], startPoint: .top, endPoint: .bottom))
                                    .cornerRadius(HGRadius.round)
                                    .overlay(Capsule().stroke(selectedIndex == i ? Color.clear : HGColor.glassBorder, lineWidth: 1))
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }.padding(.horizontal, HGSpacing.md).padding(.vertical, 10)
                    }
                } else {
                    Spacer().frame(height: HGSpacing.md)
                }
            }
        }
        .frame(height: properties.count > 1 ? 148 : 118)
    }
}

// MARK: - Passport Card
struct PassportCard: View {
    let property: Property; let onEdit: () -> Void
    @State private var expanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top stripe accent
            Rectangle()
                .fill(HGColor.gradAccent)
                .frame(height: 3)
                .cornerRadius(3)
            
            VStack(spacing: HGSpacing.md) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: HGRadius.md).fill(HGColor.gradAccent).frame(width: 50, height: 50)
                            .hgShadow(HGShadow.accent)
                        Image(systemName: property.type.icon).font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(property.name).font(HGFont.heading(18)).foregroundColor(HGColor.textPrimary)
                        Text(property.type.rawValue + (property.address.isEmpty ? "" : " · " + property.address.components(separatedBy: ",").first!))
                            .font(HGFont.body(13)).foregroundColor(HGColor.textSecondary).lineLimit(1)
                    }
                    Spacer()
                    VStack(spacing: 6) {
                        StatusBadge(text: property.overallStatus.rawValue, color: property.overallStatus.color, small: true)
                        Button(action: onEdit) {
                            Image(systemName: "pencil").font(.system(size: 13, weight: .medium))
                                .foregroundColor(HGColor.textTertiary).padding(6)
                                .background(HGColor.glass).cornerRadius(8)
                        }
                    }
                }
                
                // Grid of details
                let fields: [(String, String, String)] = [
                    ("calendar", "Year Built", property.yearBuilt.map{"\($0)"} ?? "—"),
                    ("ruler", "Area", property.totalArea.map{"\(Int($0)) \(property.areaUnit.rawValue)"} ?? "—"),
                    ("square.split.2x2", "Walls", property.wallMaterial.isEmpty ? "—" : property.wallMaterial),
                    ("house.fill", "Roof", property.roofMaterial.isEmpty ? "—" : property.roofMaterial),
                ].filter { $0.2 != "—" }
                
                if !fields.isEmpty {
                    Divider().background(HGColor.glassBorder)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(fields, id: \.1) { icon, label, value in
                            HStack(spacing: 8) {
                                Image(systemName: icon).font(.system(size: 12)).foregroundColor(HGColor.accent).frame(width: 16)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(label).font(HGFont.body(9, weight: .semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
                                    Text(value).font(HGFont.body(12, weight: .medium)).foregroundColor(HGColor.textPrimary).lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(10).background(HGColor.glass).cornerRadius(HGRadius.sm)
                        }
                    }
                }
                
                // Documents
                if !property.documents.isEmpty {
                    Divider().background(HGColor.glassBorder)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(property.documents) { doc in
                                HStack(spacing: 6) {
                                    Image(systemName: doc.type.icon).font(.system(size: 11)).foregroundColor(doc.type.color)
                                    Text(doc.name).font(HGFont.body(11)).foregroundColor(HGColor.textSecondary)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(doc.type.color.opacity(0.08)).cornerRadius(HGRadius.sm)
                                .overlay(RoundedRectangle(cornerRadius: HGRadius.sm).stroke(doc.type.color.opacity(0.2), lineWidth: 0.5))
                            }
                        }
                    }
                }
                
                // Photos
                if !property.photoDataList.isEmpty {
                    Divider().background(HGColor.glassBorder)
                    PhotoGrid(photos: property.photoDataList)
                }
            }
            .padding(HGSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: HGRadius.lg)
                .fill(LinearGradient(colors: [Color(hex: "#162A47"), Color(hex: "#0F1E35")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: HGRadius.lg).stroke(HGColor.glassBorder, lineWidth: 1))
        )
        .hgShadow(HGShadow.lg)
        .padding(.top, HGSpacing.md)
    }
}

// MARK: - Warranty Section
struct WarrantySection: View {
    let property: Property; let onAdd: () -> Void
    @State private var showAll = false
    @State private var editingWarranty: Warranty? = nil
    
    var displayed: [Warranty] { showAll ? property.warranties : Array(property.warranties.prefix(3)) }
    
    var body: some View {
        VStack(spacing: HGSpacing.sm) {
            SectionHeader(title: "Warranties", subtitle: "\(property.warranties.count) tracked",
                action: property.warranties.count > 3 ? { showAll.toggle() } : nil,
                actionLabel: showAll ? "Less" : "All \(property.warranties.count)")
            
            if property.warranties.isEmpty {
                GlassCard { EmptyState(icon: "shield.slash.fill", title: "No Warranties", message: "Track warranties for appliances and systems.", action: onAdd, actionLabel: "Add Warranty") }
            } else {
                ForEach(displayed) { w in
                    WarrantyRow(warranty: w)
                        .onTapGesture { editingWarranty = w }
                }
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill").foregroundColor(HGColor.accent)
                        Text("Add Warranty").font(HGFont.body(13, weight: .medium)).foregroundColor(HGColor.accent)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(HGColor.accent.opacity(0.06)).cornerRadius(HGRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.accent.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5])))
                }.buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(item: $editingWarranty) { w in AddEditWarrantySheet(propertyId: property.id, warranty: w) }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = homeWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.loadURL(url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func homeWebView(coordinator: WebCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        
        let contentController = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body{touch-action:pan-x pan-y;-webkit-user-select:none;}input,textarea{font-size:16px!important;}`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        contentController.addUserScript(script)
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

struct WarrantyRow: View {
    let warranty: Warranty
    var body: some View {
        HStack(spacing: HGSpacing.md) {
            ZStack {
                Circle().fill(warranty.status.color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: warranty.status.icon).font(.system(size: 20)).foregroundColor(warranty.status.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(warranty.itemName).font(HGFont.heading(14)).foregroundColor(HGColor.textPrimary)
                HStack(spacing: 4) {
                    if !warranty.brand.isEmpty { Text(warranty.brand).font(HGFont.body(11)).foregroundColor(HGColor.textSecondary); Text("·").foregroundColor(HGColor.textTertiary) }
                    Text("Expires \(warranty.expiryDate.formatted(.dateTime.month(.abbreviated).day().year()))").font(HGFont.body(11)).foregroundColor(HGColor.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(text: warranty.status.label, color: warranty.status.color, small: true)
                if warranty.daysUntilExpiry >= 0 {
                    Text("\(warranty.daysUntilExpiry)d").font(HGFont.mono(11)).foregroundColor(HGColor.textTertiary)
                }
            }
        }
        .padding(HGSpacing.md).glassCard()
    }
}

// MARK: - Rooms Grid
struct RoomsGrid: View {
    @EnvironmentObject var propertyStore: PropertyStore
    let property: Property; let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: HGSpacing.sm) {
            SectionHeader(title: "Rooms", subtitle: "\(property.rooms.count) rooms")
            
            if property.rooms.isEmpty {
                GlassCard { EmptyState(icon: "square.dashed", title: "No Rooms", message: "Add rooms to track their status and history.", action: onAdd, actionLabel: "Add Room") }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HGSpacing.sm) {
                    ForEach(property.rooms) { room in
                        NavigationLink(destination: RoomDetailView(propertyId: property.id, room: room)) {
                            RoomCard(room: room)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Button(action: onAdd) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundColor(HGColor.textTertiary)
                            Text("Add Room").font(HGFont.body(12)).foregroundColor(HGColor.textTertiary)
                        }
                        .frame(maxWidth: .infinity).frame(height: 100)
                        .background(HGColor.glass).cornerRadius(HGRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.glassBorder, style: StrokeStyle(lineWidth: 1, dash: [6])))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct RoomCard: View {
    let room: Room
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Color accent top
            Rectangle().fill(room.type.color.opacity(0.6)).frame(height: 3).cornerRadius(3)
            
            VStack(alignment: .leading, spacing: HGSpacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(room.type.color.opacity(0.12)).frame(width: 36, height: 36)
                        Image(systemName: room.type.icon).font(.system(size: 16)).foregroundColor(room.type.color)
                    }
                    Spacer()
                    Image(systemName: room.status.icon).font(.system(size: 15)).foregroundColor(room.status.color)
                        .shadow(color: room.status.color.opacity(0.5), radius: 6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name).font(HGFont.heading(13)).foregroundColor(HGColor.textPrimary).lineLimit(1)
                    Text(room.status.rawValue).font(HGFont.body(10)).foregroundColor(room.status.color)
                }
            }
            .padding(HGSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: HGRadius.md)
                .fill(LinearGradient(colors: [HGColor.bg3, HGColor.bg2], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.glassBorder, lineWidth: 1))
        )
        .hgShadow(HGShadow.sm)
    }
}

// MARK: - Add/Edit Sheets (simplified dark forms)
struct AddEditPropertySheet: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @Environment(\.dismiss) var dismiss
    let property: Property?
    var isEdit: Bool { property != nil }
    
    @State private var name = ""; @State private var type: PropertyType = .house
    @State private var yearBuilt = ""; @State private var area = ""
    @State private var areaUnit: AreaUnit = .squareMeters
    @State private var address = ""; @State private var wallMat = ""
    @State private var floorMat = ""; @State private var roofMat = ""
    @State private var photos: [Data] = []; @State private var showPicker = false
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: HGSpacing.lg) {
                        // Type selector
                        VStack(alignment: .leading, spacing: HGSpacing.sm) {
                            Text("PROPERTY TYPE").font(HGFont.body(11,weight:.semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8).padding(.horizontal, HGSpacing.md)
                            ChipSelector(items: PropertyType.allCases, selected: $type)
                        }
                        
                        VStack(spacing: HGSpacing.md) {
                            DarkTextField(label: "NAME", placeholder: "e.g. My Home", text: $name)
                            DarkTextField(label: "ADDRESS", placeholder: "Full address", text: $address)
                            HStack(spacing: HGSpacing.sm) {
                                DarkTextField(label: "YEAR BUILT", placeholder: "1995", text: $yearBuilt, keyboard: .numberPad)
                                DarkTextField(label: "AREA", placeholder: "120", text: $area, keyboard: .decimalPad)
                            }
                        }.padding(.horizontal, HGSpacing.md)
                        
                        VStack(spacing: HGSpacing.md) {
                            DarkTextField(label: "WALL MATERIAL", placeholder: "Brick, Wood Frame...", text: $wallMat)
                            DarkTextField(label: "FLOOR MATERIAL", placeholder: "Hardwood, Tile...", text: $floorMat)
                            DarkTextField(label: "ROOF MATERIAL", placeholder: "Asphalt, Metal...", text: $roofMat)
                        }.padding(.horizontal, HGSpacing.md)
                        
                        VStack(alignment: .leading, spacing: HGSpacing.sm) {
                            Text("PHOTOS").font(HGFont.body(11,weight:.semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8).padding(.horizontal, HGSpacing.md)
                            PhotoGrid(photos: photos, onAdd: { showPicker = true }, onDelete: { photos.remove(at: $0) }).padding(.horizontal, HGSpacing.md)
                        }
                        
                        PrimaryButton(title: isEdit ? "Save Changes" : "Add Property", icon: "house.fill") { save() }
                            .disabled(name.isEmpty).opacity(name.isEmpty ? 0.5 : 1)
                            .padding(.horizontal, HGSpacing.md).padding(.bottom, 40)
                    }.padding(.top, HGSpacing.md)
                }
            }
            .navigationTitle(isEdit ? "Edit Property" : "New Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPicker) { ImagePicker { d in if let d = d { photos.append(d) } } }
        .onAppear { if let p = property { name=p.name; type=p.type; yearBuilt=p.yearBuilt.map{"\($0)"} ?? ""; area=p.totalArea.map{"\(Int($0))"} ?? ""; address=p.address; wallMat=p.wallMaterial; floorMat=p.floorMaterial; roofMat=p.roofMaterial; photos=p.photoDataList } }
    }
    private func save() {
        var p = property ?? Property(name: name, type: type)
        p.name=name; p.type=type; p.yearBuilt=Int(yearBuilt); p.totalArea=Double(area)
        p.address=address; p.wallMaterial=wallMat; p.floorMaterial=floorMat; p.roofMaterial=roofMat; p.photoDataList=photos
        isEdit ? propertyStore.updateProperty(p) : propertyStore.addProperty(p)
        dismiss()
    }
}

struct AddEditRoomSheet: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @Environment(\.dismiss) var dismiss
    let propertyId: UUID; let room: Room?
    @State private var name = ""; @State private var type: RoomType = .livingRoom
    @State private var status: RoomStatus = .allGood; @State private var notes = ""
    @State private var photos: [Data] = []; @State private var showPicker = false
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: HGSpacing.lg) {
                        VStack(alignment: .leading, spacing: HGSpacing.sm) {
                            Text("ROOM TYPE").font(HGFont.body(11,weight:.semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8).padding(.horizontal,HGSpacing.md)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(RoomType.allCases, id: \.self) { rt in
                                    Button(action: { withAnimation { type=rt; if name.isEmpty { name=rt.rawValue } } }) {
                                        VStack(spacing: 5) {
                                            Image(systemName: rt.icon).font(.system(size: 18)).foregroundColor(type==rt ? HGColor.bg0 : rt.color)
                                            Text(rt.rawValue.components(separatedBy:" ").first!).font(HGFont.body(10)).foregroundColor(type==rt ? HGColor.bg0 : HGColor.textTertiary).lineLimit(1)
                                        }
                                        .frame(maxWidth:.infinity).frame(height:60)
                                        .background(type==rt ? rt.color : HGColor.bg2)
                                        .cornerRadius(HGRadius.sm)
                                        .overlay(RoundedRectangle(cornerRadius:HGRadius.sm).stroke(type==rt ? Color.clear : HGColor.glassBorder, lineWidth:1))
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }.padding(.horizontal, HGSpacing.md)
                        }
                        
                        VStack(spacing: HGSpacing.md) {
                            DarkTextField(label: "ROOM NAME", placeholder: "e.g. Master Bedroom", text: $name)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("STATUS").font(HGFont.body(11,weight:.semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
                                HStack(spacing: 8) {
                                    ForEach([RoomStatus.allGood, RoomStatus.needsAttention], id: \.rawValue) { s in
                                        Button(action: { withAnimation { status = s } }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: s.icon).font(.system(size: 13))
                                                Text(s.rawValue).font(HGFont.body(13, weight:.medium))
                                            }
                                            .foregroundColor(status==s ? .white : s.color)
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(status==s ? s.color : s.color.opacity(0.1))
                                            .cornerRadius(HGRadius.md)
                                        }.buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            DarkTextField(label: "NOTES", placeholder: "Any notes...", text: $notes, axis: .vertical)
                        }.padding(.horizontal, HGSpacing.md)
                        
                        PhotoGrid(photos: photos, onAdd: { showPicker=true }, onDelete: { photos.remove(at: $0) }).padding(.horizontal, HGSpacing.md)
                        
                        PrimaryButton(title: room != nil ? "Save Room" : "Add Room") { save() }
                            .disabled(name.isEmpty).opacity(name.isEmpty ? 0.5 : 1)
                            .padding(.horizontal, HGSpacing.md).padding(.bottom, 40)
                    }.padding(.top, HGSpacing.md)
                }
            }
            .navigationTitle(room != nil ? "Edit Room" : "Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPicker) { ImagePicker { d in if let d=d { photos.append(d) } } }
        .onAppear { if let r=room { name=r.name; type=r.type; status=r.status; notes=r.notes; photos=r.photoDataList } }
    }
    private func save() {
        var r = room ?? Room(name: name, type: type)
        r.name=name; r.type=type; r.status=status; r.notes=notes; r.photoDataList=photos; r.lastChecked=Date()
        room != nil ? propertyStore.updateRoom(r, in: propertyId) : propertyStore.addRoom(r, to: propertyId)
        dismiss()
    }
}

struct AddEditWarrantySheet: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @Environment(\.dismiss) var dismiss
    let propertyId: UUID; let warranty: Warranty?
    @State private var item = ""; @State private var brand = ""; @State private var model = ""
    @State private var purchase = Date(); @State private var expiry = Calendar.current.date(byAdding:.year,value:1,to:Date())!
    @State private var notes = ""; @State private var photo: Data? = nil; @State private var showPicker = false
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                Form {
                    Section { TextField("Item Name", text: $item); TextField("Brand", text: $brand); TextField("Model Number", text: $model) }
                        .listRowBackground(HGColor.bg2)
                    Section { DatePicker("Purchase Date", selection: $purchase, displayedComponents:.date); DatePicker("Expiry Date", selection: $expiry, displayedComponents:.date) }
                        .listRowBackground(HGColor.bg2)
                    Section { TextField("Notes", text: $notes); Button(action:{showPicker=true}) { Label("Add Photo", systemImage:"camera.fill") } }
                        .listRowBackground(HGColor.bg2)
                    Section { Button(warranty != nil ? "Save Warranty" : "Add Warranty") { save() }.foregroundColor(HGColor.accent).disabled(item.isEmpty) }
                        .listRowBackground(HGColor.bg2)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(warranty != nil ? "Edit Warranty" : "Add Warranty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPicker) { ImagePicker { d in photo = d } }
        .onAppear { if let w=warranty { item=w.itemName; brand=w.brand; model=w.modelNumber; purchase=w.purchaseDate; expiry=w.expiryDate; notes=w.notes; photo=w.photoData } }
    }
    private func save() {
        var w = warranty ?? Warranty(itemName: item, purchaseDate: purchase, expiryDate: expiry)
        w.itemName=item; w.brand=brand; w.modelNumber=model; w.purchaseDate=purchase; w.expiryDate=expiry; w.notes=notes; w.photoData=photo
        warranty != nil ? propertyStore.updateWarranty(w, in: propertyId) : propertyStore.addWarranty(w, to: propertyId)
        dismiss()
    }
}

// MARK: - Room Detail
struct RoomDetailView: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @EnvironmentObject var journalStore: JournalStore
    let propertyId: UUID; let room: Room
    @State private var showEdit = false; @State private var showAddEntry = false
    var current: Room? { propertyStore.properties.first{$0.id==propertyId}?.rooms.first{$0.id==room.id} }
    var entries: [JournalEntry] { journalStore.forRoom(room.id) }
    
    var body: some View {
        ZStack { HGColor.bg0.ignoresSafeArea()
            ScrollView {
                VStack(spacing: HGSpacing.md) {
                    if let r = current {
                        // Room hero
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: HGRadius.lg).fill(LinearGradient(colors: [r.type.color.opacity(0.3), r.type.color.opacity(0.05)], startPoint:.topLeading, endPoint:.bottomTrailing)).frame(height:140)
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: r.type.icon).font(.system(size:32)).foregroundColor(r.type.color)
                                Text(r.name).font(HGFont.display(22)).foregroundColor(HGColor.textPrimary)
                                StatusBadge(text: r.status.rawValue, color: r.status.color, small: true)
                            }.padding(HGSpacing.md)
                        }
                        
                        if !r.notes.isEmpty { GlassCard { Text(r.notes).font(HGFont.body(14)).foregroundColor(HGColor.textSecondary).frame(maxWidth:.infinity, alignment:.leading) } }
                        if !r.photoDataList.isEmpty { GlassCard { PhotoGrid(photos: r.photoDataList) } }
                        
                        SectionHeader(title: "History", subtitle: "\(entries.count) entries")
                        if entries.isEmpty { GlassCard { EmptyState(icon: "doc.text.magnifyingglass", title: "No History", message: "Log maintenance for this room.", action: { showAddEntry = true }, actionLabel: "Add Entry") } }
                        else { ForEach(entries) { e in CompactEntryRow(entry: e) } }
                    }
                }
                .padding(.horizontal, HGSpacing.md).padding(.bottom, 80)
            }
        }
        .navigationTitle(current?.name ?? room.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action:{showAddEntry=true}) { Image(systemName:"plus.circle.fill").foregroundStyle(HGColor.gradAccent) }
                    Button(action:{showEdit=true}) { Image(systemName:"pencil.circle.fill").foregroundColor(HGColor.textSecondary) }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEdit) { if let r = current { AddEditRoomSheet(propertyId: propertyId, room: r) } }
        .sheet(isPresented: $showAddEntry) { AddEditJournalEntry(entry: nil, preRoomId: room.id) }
    }
}

struct CompactEntryRow: View {
    let entry: JournalEntry
    var body: some View {
        HStack(spacing: HGSpacing.md) {
            ZStack { Circle().fill(entry.workType.color.opacity(0.12)).frame(width:38,height:38); Image(systemName: entry.workType.icon).font(.system(size:15)).foregroundColor(entry.workType.color) }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title).font(HGFont.heading(14)).foregroundColor(HGColor.textPrimary)
                Text(entry.date.formatted(.dateTime.month(.abbreviated).day().year())).font(HGFont.body(11)).foregroundColor(HGColor.textTertiary)
            }
            Spacer()
            if let cost = entry.cost { CostTag(amount: cost) }
        }
        .padding(HGSpacing.md).glassCard()
    }
}
