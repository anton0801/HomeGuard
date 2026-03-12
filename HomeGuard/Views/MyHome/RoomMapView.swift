import SwiftUI

#Preview {
    RoomMapView()
        .environmentObject(PropertyStore())
        .environmentObject(JournalStore())
}

// MARK: - Room Map Models
struct RoomTile: Identifiable, Codable {
    var id = UUID()
    var roomId: UUID?
    var name: String
    var type: RoomType
    var x: CGFloat      // grid column (0-based)
    var y: CGFloat      // grid row (0-based)
    var width: CGFloat  // in grid units
    var height: CGFloat // in grid units
    var color: Color { type.color }
}

// MARK: - Room Map View
struct RoomMapView: View {
    @EnvironmentObject var propertyStore: PropertyStore
    @EnvironmentObject var journalStore: JournalStore

    @State private var tiles: [RoomTile] = []
    @State private var selectedTile: UUID? = nil
    @State private var draggingTile: UUID? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var showAddPanel = false
    @State private var editingTile: RoomTile? = nil
    @State private var showTileDetail: RoomTile? = nil

    let gridSize: CGFloat = 60
    let gridCols = 8
    let gridRows = 10

    var prop: Property? { propertyStore.selected }
    var saveKey: String { "hg.roommap.\(prop?.id.uuidString ?? "default")" }

    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()

            VStack(spacing: 0) {
                MapHeader(
                    propertyName: prop?.name ?? "Floor Plan",
                    tileCount: tiles.count,
                    onAdd: { showAddPanel = true },
                    onClear: { withAnimation { tiles = [] }; saveTiles() }
                )

                if tiles.isEmpty && prop?.rooms.isEmpty == false {
                    // Auto-generate hint
                    VStack(spacing: HGSpacing.lg) {
                        Spacer()
                        ZStack {
                            Circle().fill(HGColor.accent.opacity(0.08)).frame(width: 120, height: 120)
                            Image(systemName: "map.fill")
                                .font(.system(size: 50, weight: .thin))
                                .foregroundStyle(HGColor.gradAccent)
                        }
                        VStack(spacing: 10) {
                            Text("Build Your Floor Plan")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(HGColor.textPrimary)
                            Text("Drag rooms onto the grid to create\nan interactive map of your property")
                                .font(HGFont.body(14))
                                .foregroundColor(HGColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        HStack(spacing: HGSpacing.sm) {
                            PrimaryButton(title: "Auto-Generate", icon: "wand.and.stars", gradient: HGColor.gradAccent) {
                                autoGenerate()
                            }
                            SecondaryButton(title: "Add Room", icon: "plus") {
                                showAddPanel = true
                            }
                        }
                        .padding(.horizontal, HGSpacing.xl)
                        Spacer()
                    }
                } else {
                    // Grid canvas
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            // Grid background
                            GridCanvas(cols: gridCols, rows: gridRows, cellSize: gridSize)

                            // Placed tiles
                            ForEach(tiles) { tile in
                                PlacedTileView(
                                    tile: tile,
                                    cellSize: gridSize,
                                    isSelected: selectedTile == tile.id,
                                    isDragging: draggingTile == tile.id,
                                    dragOffset: draggingTile == tile.id ? dragOffset : .zero,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedTile = selectedTile == tile.id ? nil : tile.id
                                        }
                                    },
                                    onDoubleTap: { showTileDetail = tile },
                                    onDelete: { deleteTile(tile) }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { val in
                                            draggingTile = tile.id
                                            dragOffset = val.translation
                                        }
                                        .onEnded { val in
                                            snapTile(tile, translation: val.translation)
                                            draggingTile = nil
                                            dragOffset = .zero
                                        }
                                )
                            }
                        }
                        .frame(
                            width: CGFloat(gridCols) * gridSize + 2,
                            height: CGFloat(gridRows) * gridSize + 2
                        )
                        .padding(HGSpacing.md)
                    }
                    .background(Color(hex: "#040A14"))

                    // Legend
                    if !tiles.isEmpty {
                        MapLegend(tiles: tiles, journalStore: journalStore)
                    }
                }
            }

            // Add room panel
            if showAddPanel {
                AddRoomToMapPanel(
                    rooms: prop?.rooms ?? [],
                    existingTileRoomIds: tiles.compactMap { $0.roomId },
                    onAdd: { tile in
                        withAnimation(.spring()) { tiles.append(tile) }
                        saveTiles()
                        showAddPanel = false
                    },
                    onDismiss: { showAddPanel = false }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .sheet(item: $showTileDetail) { tile in
            TileDetailSheet(tile: tile, journalEntries: journalStore.entries.filter { $0.roomId == tile.roomId })
        }
        .onAppear { loadTiles() }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAddPanel)
    }

    // MARK: - Auto-generate layout
    private func autoGenerate() {
        guard let rooms = prop?.rooms else { return }
        var generated: [RoomTile] = []
        let cols = 4
        for (i, room) in rooms.enumerated() {
            let col = CGFloat((i % cols) * 2)
            let row = CGFloat((i / cols) * 2)
            generated.append(RoomTile(
                roomId: room.id,
                name: room.name,
                type: room.type,
                x: col, y: row,
                width: 2, height: 2
            ))
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { tiles = generated }
        saveTiles()
    }

    private func snapTile(_ tile: RoomTile, translation: CGSize) {
        guard let idx = tiles.firstIndex(where: { $0.id == tile.id }) else { return }
        let deltaCol = (translation.width / gridSize).rounded()
        let deltaRow = (translation.height / gridSize).rounded()
        let newX = max(0, min(CGFloat(gridCols) - tile.width, tile.x + deltaCol))
        let newY = max(0, min(CGFloat(gridRows) - tile.height, tile.y + deltaRow))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tiles[idx].x = newX
            tiles[idx].y = newY
        }
        saveTiles()
    }

    private func deleteTile(_ tile: RoomTile) {
        withAnimation(.spring()) { tiles.removeAll { $0.id == tile.id } }
        if selectedTile == tile.id { selectedTile = nil }
        saveTiles()
    }

    private func saveTiles() {
        // Encode CGFloat-based struct (custom encode needed for Color)
        let data = tiles.map { t in
            ["id": t.id.uuidString, "name": t.name, "type": t.type.rawValue,
             "x": "\(t.x)", "y": "\(t.y)", "w": "\(t.width)", "h": "\(t.height)",
             "roomId": t.roomId?.uuidString ?? ""]
        }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private func loadTiles() {
        guard let data = UserDefaults.standard.array(forKey: saveKey) as? [[String: String]] else { return }
        tiles = data.compactMap { d in
            guard let name = d["name"], let typeRaw = d["type"],
                  let type = RoomType(rawValue: typeRaw),
                  let x = Double(d["x"] ?? ""), let y = Double(d["y"] ?? ""),
                  let w = Double(d["w"] ?? ""), let h = Double(d["h"] ?? "") else { return nil }
            var tile = RoomTile(name: name, type: type, x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
            if let rIdStr = d["roomId"], let rId = UUID(uuidString: rIdStr) { tile.roomId = rId }
            if let idStr = d["id"], let id = UUID(uuidString: idStr) { tile.id = id }
            return tile
        }
    }
}

// MARK: - Grid Canvas
struct GridCanvas: View {
    let cols: Int; let rows: Int; let cellSize: CGFloat

    var body: some View {
        Canvas { ctx, size in
            // Fill
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "#060D18")))

            // Grid lines
            for col in 0...cols {
                let x = CGFloat(col) * cellSize
                var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(p, with: .color(Color.white.opacity(col == 0 || col == cols ? 0.12 : 0.04)), lineWidth: col == 0 || col == cols ? 1 : 0.5)
            }
            for row in 0...rows {
                let y = CGFloat(row) * cellSize
                var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: .color(Color.white.opacity(row == 0 || row == rows ? 0.12 : 0.04)), lineWidth: row == 0 || row == rows ? 1 : 0.5)
            }

            // Corner dots
            for col in 0...cols {
                for row in 0...rows {
                    let pt = CGPoint(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize)
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x-1, y: pt.y-1, width: 2, height: 2)), with: .color(.white.opacity(0.08)))
                }
            }
        }
        .frame(width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
    }
}

// MARK: - Placed Tile
struct PlacedTileView: View {
    let tile: RoomTile
    let cellSize: CGFloat
    let isSelected: Bool
    let isDragging: Bool
    let dragOffset: CGSize
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [tile.color.opacity(0.35), tile.color.opacity(0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? tile.color : tile.color.opacity(0.4),
                    lineWidth: isSelected ? 2 : 1
                )

            // Glow when selected
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tile.color.opacity(0.3), lineWidth: 6)
                    .blur(radius: 4)
            }

            VStack(spacing: 3) {
                Image(systemName: tile.type.icon)
                    .font(.system(size: min(cellSize * tile.width * 0.22, 22), weight: .semibold))
                    .foregroundColor(tile.color)
                    .shadow(color: tile.color.opacity(0.5), radius: 6)

                if tile.width >= 2 {
                    Text(tile.name)
                        .font(.system(size: min(cellSize * 0.18, 11), weight: .semibold, design: .rounded))
                        .foregroundColor(HGColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(4)

            // Delete button when selected
            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(HGColor.danger)
                        .background(Color.black.opacity(0.5).clipShape(Circle()))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(4)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(
            width: tile.width * cellSize - 4,
            height: tile.height * cellSize - 4
        )
        .position(
            x: tile.x * cellSize + (tile.width * cellSize) / 2 + (isDragging ? dragOffset.width : 0),
            y: tile.y * cellSize + (tile.height * cellSize) / 2 + (isDragging ? dragOffset.height : 0)
        )
        .shadow(
            color: isDragging ? tile.color.opacity(0.4) : .black.opacity(0.3),
            radius: isDragging ? 16 : 6
        )
        .scaleEffect(isDragging ? 1.06 : (isSelected ? 1.02 : 1.0))
        .zIndex(isDragging ? 100 : (isSelected ? 10 : 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2), value: isDragging)
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture { onTap() }
    }
}

// MARK: - Map Header
struct MapHeader: View {
    let propertyName: String
    let tileCount: Int
    let onAdd: () -> Void
    let onClear: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            HeroBackground(color1: Color(hex: "#4ECDC4"), color2: Color(hex: "#F5A623"))
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#4ECDC4"))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: "#4ECDC4").opacity(0.12)).cornerRadius(HGRadius.round)
                        Text("FLOOR PLAN").font(HGFont.body(11, weight: .bold))
                            .foregroundColor(Color(hex: "#4ECDC4")).tracking(1.2)
                    }
                    Text(propertyName)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(HGColor.textPrimary)
                    Text("\(tileCount) rooms placed")
                        .font(HGFont.body(13)).foregroundColor(HGColor.textSecondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    if tileCount > 0 {
                        Button(action: onClear) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(HGColor.danger)
                                .padding(8)
                                .background(HGColor.danger.opacity(0.1)).cornerRadius(8)
                        }
                    }
                    Button(action: onAdd) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Room")
                        }
                        .font(HGFont.body(13, weight: .semibold))
                        .foregroundColor(HGColor.bg0)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(HGColor.gradCool).cornerRadius(HGRadius.round)
                        .hgShadow(HGShadow.cool)
                    }
                }
            }
            .padding(.horizontal, HGSpacing.md)
            .padding(.top, 56)
            .padding(.bottom, HGSpacing.md)
        }
        .frame(height: 130)
    }
}

// MARK: - Map Legend
struct MapLegend: View {
    let tiles: [RoomTile]
    let journalStore: JournalStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HGSpacing.sm) {
                ForEach(tiles) { tile in
                    HStack(spacing: 6) {
                        Circle().fill(tile.color).frame(width: 8, height: 8)
                            .shadow(color: tile.color.opacity(0.6), radius: 4)
                        Text(tile.name).font(HGFont.body(11, weight: .medium))
                            .foregroundColor(HGColor.textSecondary)
                        let count = journalStore.entries.filter { $0.roomId == tile.roomId }.count
                        if count > 0 {
                            Text("\(count)").font(HGFont.mono(10))
                                .foregroundColor(tile.color)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(tile.color.opacity(0.12)).cornerRadius(HGRadius.round)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(HGColor.bg2).cornerRadius(HGRadius.round)
                    .overlay(Capsule().stroke(HGColor.glassBorder, lineWidth: 0.5))
                }
            }
            .padding(.horizontal, HGSpacing.md)
            .padding(.vertical, 10)
        }
        .background(HGColor.bg1)
    }
}

// MARK: - Add Room to Map Panel
struct AddRoomToMapPanel: View {
    let rooms: [Room]
    let existingTileRoomIds: [UUID]
    let onAdd: (RoomTile) -> Void
    let onDismiss: () -> Void

    @State private var selectedRoom: Room? = nil
    @State private var tileW: CGFloat = 2
    @State private var tileH: CGFloat = 2
    @State private var customName = ""

    var availableRooms: [Room] { rooms.filter { !existingTileRoomIds.contains($0.id) } }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: HGSpacing.lg) {
                    // Handle
                    Capsule().fill(HGColor.textTertiary).frame(width: 36, height: 4).padding(.top, 8)

                    Text("Add Room to Map")
                        .font(HGFont.heading(18)).foregroundColor(HGColor.textPrimary)

                    if availableRooms.isEmpty {
                        Text("All rooms are already on the map.\nAdd more rooms in the My Home tab.")
                            .font(HGFont.body(14)).foregroundColor(HGColor.textSecondary)
                            .multilineTextAlignment(.center).padding()
                    } else {
                        // Room picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(availableRooms) { room in
                                    Button(action: { selectedRoom = room; customName = room.name }) {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedRoom?.id == room.id ? room.type.color : room.type.color.opacity(0.12))
                                                    .frame(width: 52, height: 52)
                                                Image(systemName: room.type.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(selectedRoom?.id == room.id ? .white : room.type.color)
                                            }
                                            Text(room.name).font(HGFont.body(11)).foregroundColor(HGColor.textSecondary).lineLimit(1)
                                        }
                                        .frame(width: 64)
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }.padding(.horizontal, HGSpacing.md)
                        }

                        // Size picker
                        VStack(spacing: 10) {
                            HStack {
                                Text("SIZE").font(HGFont.body(11, weight: .bold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
                                Spacer()
                                Text("\(Int(tileW)) × \(Int(tileH)) cells").font(HGFont.mono(12)).foregroundColor(HGColor.accent)
                            }
                            HStack(spacing: 12) {
                                ForEach([(1.0, 1.0, "1×1"), (2.0, 1.0, "2×1"), (2.0, 2.0, "2×2"), (3.0, 2.0, "3×2")] as [(CGFloat, CGFloat, String)], id: \.2) { w, h, label in
                                    Button(action: { tileW = w; tileH = h }) {
                                        Text(label)
                                            .font(HGFont.body(12, weight: tileW == w && tileH == h ? .bold : .regular))
                                            .foregroundColor(tileW == w && tileH == h ? HGColor.bg0 : HGColor.textSecondary)
                                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                                            .background(tileW == w && tileH == h ? HGColor.accent : HGColor.bg2)
                                            .cornerRadius(HGRadius.sm)
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }
                        }.padding(.horizontal, HGSpacing.md)

                        PrimaryButton(title: "Place on Map", icon: "mappin.circle.fill", gradient: HGColor.gradAccent) {
                            guard let room = selectedRoom else { return }
                            onAdd(RoomTile(roomId: room.id, name: room.name, type: room.type, x: 0, y: 0, width: tileW, height: tileH))
                        }
                        .disabled(selectedRoom == nil)
                        .opacity(selectedRoom == nil ? 0.5 : 1)
                        .padding(.horizontal, HGSpacing.md)
                    }

                    Button("Cancel", action: onDismiss)
                        .foregroundColor(HGColor.textSecondary)
                        .padding(.bottom, 30)
                }
                .padding(.top, 4)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "#0A1628"))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(HGColor.glassBorder, lineWidth: 1))
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }
}

// MARK: - Tile Detail Sheet
struct TileDetailSheet: View {
    let tile: RoomTile
    let journalEntries: [JournalEntry]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                HGColor.bg0.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: HGSpacing.md) {
                        // Hero
                        ZStack {
                            RoundedRectangle(cornerRadius: HGRadius.lg)
                                .fill(LinearGradient(colors: [tile.color.opacity(0.3), tile.color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 100)
                            VStack(spacing: 8) {
                                Image(systemName: tile.type.icon).font(.system(size: 34)).foregroundColor(tile.color)
                                Text(tile.name).font(HGFont.display(20)).foregroundColor(HGColor.textPrimary)
                            }
                        }

                        if journalEntries.isEmpty {
                            EmptyState(icon: "doc.text.magnifyingglass", title: "No History", message: "No journal entries for this room yet.")
                        } else {
                            VStack(spacing: HGSpacing.sm) {
                                SectionHeader(title: "Repair History", subtitle: "\(journalEntries.count) entries")
                                ForEach(journalEntries) { e in
                                    CompactEntryRow(entry: e)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, HGSpacing.md)
                    .padding(.vertical, HGSpacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(HGColor.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
