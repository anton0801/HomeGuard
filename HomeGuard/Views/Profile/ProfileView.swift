import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var propertyStore: PropertyStore
    @EnvironmentObject var journalStore: JournalStore
    @EnvironmentObject var reminderStore: ReminderStore
    @State private var showEditProfile  = false
    @State private var showDeleteConfirm = false
    @State private var showSignOutConfirm = false
    @State private var showExportPicker = false
    @State private var exportData: Data? = nil
    @State private var showUpgradeSheet = false
    @State private var cardAppeared = false
    
    var user: HGUser? { authService.currentUser }
    
    var body: some View {
        ZStack {
            HGColor.bg0.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile hero header
                    ProfileHeroHeader(user: user, onEdit: { showEditProfile = true })
                    
                    VStack(spacing: HGSpacing.lg) {
                        // Guest banner
                        if user?.isGuest == true {
                            GuestBanner(onUpgrade: { showUpgradeSheet = true })
                        }
                        
                        // Stats overview
                        ProfileStatsGrid(
                            properties: propertyStore.properties.count,
                            rooms: propertyStore.properties.flatMap{$0.rooms}.count,
                            entries: journalStore.entries.count,
                            reminders: reminderStore.reminders.count
                        )
                        
                        // Export section
                        VStack(spacing: HGSpacing.sm) {
                            SectionLabel("EXPORT & REPORTS")
                            ForEach(propertyStore.properties) { prop in
                                ProfileActionRow(
                                    icon: "arrow.up.doc.fill",
                                    iconColor: HGColor.info,
                                    title: "Export \(prop.name) Report",
                                    subtitle: "\(journalStore.forProperty(prop.id).count) entries → PDF"
                                ) {
                                    if let data = PDFExportService.export(entries: journalStore.forProperty(prop.id), property: prop) {
                                        exportData = data; showExportPicker = true
                                    }
                                }
                            }
                            if propertyStore.properties.isEmpty {
                                GlassCard { Text("Add a property to export reports").font(HGFont.body(14)).foregroundColor(HGColor.textSecondary).frame(maxWidth:.infinity, alignment:.center).padding(.vertical, 8) }
                            }
                        }
                        
                        // App settings
                        VStack(spacing: HGSpacing.sm) {
                            SectionLabel("NOTIFICATIONS")
                            ProfileActionRow(icon: "bell.badge.fill", iconColor: HGColor.accent, title: "Notification Settings", subtitle: "Manage reminder alerts") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }
                        }
                        
                        // About
                        VStack(spacing: HGSpacing.sm) {
                            SectionLabel("ABOUT")
                            GlassCard {
                                VStack(spacing: 0) {
                                    AboutRow(label: "Version", value: "2.0.0")
                                    Divider().background(HGColor.glassBorder)
                                    AboutRow(label: "Build", value: "Premium")
                                    Divider().background(HGColor.glassBorder)
                                    AboutRow(label: "Data Storage", value: "Local + Encrypted")
                                    Divider().background(HGColor.glassBorder)
                                    AboutRow(label: "Auth", value: "Firebase")
                                }
                            }
                        }
                        
                        // Account management
                        VStack(spacing: HGSpacing.sm) {
                            SectionLabel("ACCOUNT")
                            
                            ProfileActionRow(icon: "arrow.right.square.fill", iconColor: HGColor.warning, title: "Sign Out", subtitle: "You can sign back in anytime") {
                                showSignOutConfirm = true
                            }
                            
                            ProfileActionRow(icon: "trash.fill", iconColor: HGColor.danger, title: "Delete Account", subtitle: "Permanently remove your account and all data", isDestructive: true) {
                                showDeleteConfirm = true
                            }
                        }
                        
                        // Footer
                        Text("HomeGuard v2.0 · Powered by Firebase")
                            .font(HGFont.body(11))
                            .foregroundColor(HGColor.textTertiary)
                            .padding(.vertical, HGSpacing.md)
                    }
                    .padding(.horizontal, HGSpacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
        }
        .sheet(isPresented: $showExportPicker) {
            if let data = exportData { ShareSheet(items: [data]) }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradeSheet()
        }
        .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { try? authService.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll need to sign back in to access your account.") }
        .confirmationDialog("Delete Account?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task { try? await authService.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete your account. All cloud data will be removed. Local data remains on this device.") }
    }
}

// MARK: - Profile Hero
struct ProfileHeroHeader: View {
    let user: HGUser?; let onEdit: () -> Void
    @State private var appear = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with user color
            GeometryReader { geo in
                ZStack {
                    HeroBackground(
                        color1: user?.avatarColors.first ?? HGColor.accent,
                        color2: user?.avatarColors.last ?? Color(hex: "#4ECDC4")
                    )
                    // Decorative arc
                    Ellipse()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.04), .clear], startPoint:.top, endPoint:.bottom))
                        .frame(width: 600, height: 300)
                        .offset(y: 80)
                }
                .frame(width: geo.size.width)
            }
            
            
            VStack(spacing: HGSpacing.md) {
                HStack { Spacer()
                    Button(action: onEdit) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil").font(.system(size: 13))
                            Text("Edit").font(HGFont.body(13, weight: .medium))
                        }
                        .foregroundColor(HGColor.textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(HGColor.glass).cornerRadius(HGRadius.round)
                        .overlay(Capsule().stroke(HGColor.glassBorder, lineWidth: 1))
                    }
                }
                .padding(.horizontal, HGSpacing.md)
                .padding(.top, 56)
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: user?.avatarColors ?? [HGColor.accent, HGColor.accentWarm], startPoint:.topLeading, endPoint:.bottomTrailing))
                        .frame(width: 90, height: 90)
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
                        .hgShadow(HGShadow.lg)
                    
                    Text(user?.initials ?? "G")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if user?.isGuest == true {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(HGColor.bg2)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(HGColor.bg0, lineWidth: 2))
                            .offset(x: 32, y: 32)
                    }
                }
                .scaleEffect(appear ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appear)
                
                VStack(spacing: 6) {
                    Text(user?.displayName ?? "Guest User")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(HGColor.textPrimary)
                    
                    if let email = user?.email {
                        Text(email)
                            .font(HGFont.body(14))
                            .foregroundColor(HGColor.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        if user?.isGuest == true {
                            StatusBadge(text: "Guest Mode", color: HGColor.warning, small: true)
                        } else {
                            StatusBadge(text: "● Active", color: HGColor.success, small: true)
                        }
                        if let date = user?.createdAt {
                            Text("Since \(date.formatted(.dateTime.month(.abbreviated).year()))")
                                .font(HGFont.body(11))
                                .foregroundColor(HGColor.textTertiary)
                        }
                    }
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 15)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: appear)
                
                Spacer().frame(height: HGSpacing.lg)
            }
        }
        .frame(height: 310)
        .onAppear { appear = true }
    }
}

// MARK: - Guest Banner
struct GuestBanner: View {
    let onUpgrade: () -> Void
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: HGSpacing.md) {
            ZStack {
                Circle().fill(HGColor.warning.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                    .font(.system(size: 20))
                    .foregroundColor(HGColor.warning)
                    .scaleEffect(pulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Guest Mode").font(HGFont.heading(14)).foregroundColor(HGColor.textPrimary)
                Text("Create an account to sync & backup your data").font(HGFont.body(12)).foregroundColor(HGColor.textSecondary)
            }
            Spacer()
            Button(action: onUpgrade) {
                Text("Upgrade").font(HGFont.body(12, weight: .bold)).foregroundColor(HGColor.bg0)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(HGColor.gradAccent).cornerRadius(HGRadius.round)
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(HGSpacing.md)
        .background(HGColor.warning.opacity(0.06)).cornerRadius(HGRadius.lg)
        .overlay(RoundedRectangle(cornerRadius: HGRadius.lg).stroke(HGColor.warning.opacity(0.2), lineWidth: 1))
        .onAppear { pulse = true }
    }
}

// MARK: - Stats Grid
struct ProfileStatsGrid: View {
    let properties: Int; let rooms: Int; let entries: Int; let reminders: Int
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HGSpacing.sm) {
            StatTile(value: "\(properties)", label: "Properties", icon: "house.fill", color: HGColor.accent)
            StatTile(value: "\(rooms)", label: "Rooms", icon: "square.grid.2x2.fill", color: Color(hex: "#4ECDC4"))
            StatTile(value: "\(entries)", label: "Journal Entries", icon: "book.closed.fill", color: Color(hex: "#F093FB"))
            StatTile(value: "\(reminders)", label: "Reminders", icon: "bell.fill", color: Color(hex: "#23D18B"))
        }
    }
}

struct StatTile: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: HGSpacing.sm) {
            ZStack { RoundedRectangle(cornerRadius: HGRadius.sm).fill(color.opacity(0.12)).frame(width:40,height:40); Image(systemName:icon).font(.system(size:17)).foregroundColor(color) }
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(HGFont.mono(20)).foregroundColor(HGColor.textPrimary).shadow(color: color.opacity(0.3), radius: 6)
                Text(label).font(HGFont.body(11)).foregroundColor(HGColor.textSecondary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HGSpacing.md).glassCard()
    }
}

// MARK: - Action Row
struct ProfileActionRow: View {
    let icon: String; let iconColor: Color; let title: String; let subtitle: String
    var isDestructive = false; let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HGSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: HGRadius.sm).fill(iconColor.opacity(0.12)).frame(width:40,height:40)
                    Image(systemName: icon).font(.system(size: 16)).foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(HGFont.heading(14)).foregroundColor(isDestructive ? HGColor.danger : HGColor.textPrimary)
                    Text(subtitle).font(HGFont.body(12)).foregroundColor(HGColor.textSecondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(HGColor.textTertiary)
            }
            .padding(HGSpacing.md).glassCard()
        }
        .buttonStyle(PlainButtonStyle())
        .pressAnimation()
    }
}

struct AboutRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(HGFont.body(14)).foregroundColor(HGColor.textSecondary)
            Spacer()
            Text(value).font(HGFont.body(14, weight: .medium)).foregroundColor(HGColor.textPrimary)
        }.padding(.vertical, HGSpacing.sm)
    }
}

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(HGFont.body(11, weight: .bold)).foregroundColor(HGColor.textTertiary).tracking(1.2).frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ZStack { HGColor.bg0.ignoresSafeArea()
                VStack(spacing: HGSpacing.xl) {
                    // Avatar preview
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: authService.currentUser?.avatarColors ?? [HGColor.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Text((name.isEmpty ? authService.currentUser?.initials : String(name.prefix(2)).uppercased()) ?? "")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, HGSpacing.xl)
                    
                    VStack(spacing: HGSpacing.md) {
                        DarkTextField(label: "DISPLAY NAME", placeholder: "Your name", text: $name)
                        
                        if let email = authService.currentUser?.email {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EMAIL").font(HGFont.body(11, weight: .semibold)).foregroundColor(HGColor.textTertiary).tracking(0.8)
                                HStack {
                                    Text(email).font(HGFont.body(15)).foregroundColor(HGColor.textSecondary)
                                    Spacer()
                                    Text("Cannot change").font(HGFont.body(11)).foregroundColor(HGColor.textTertiary)
                                }
                                .padding(HGSpacing.md).background(HGColor.bg2).cornerRadius(HGRadius.md)
                                .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.glassBorder, lineWidth: 1))
                            }
                        }
                        
                        if let error = error { AuthErrorBanner(message: error) }
                        
                        PrimaryButton(title: "Save Changes", isLoading: isLoading) {
                            isLoading = true
                            Task {
                                do {
                                    try await authService.updateProfile(name: name)
                                    await MainActor.run { dismiss() }
                                } catch {
                                    await MainActor.run { self.error = error.localizedDescription; isLoading = false }
                                }
                            }
                        }
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal, HGSpacing.lg)
                    
                    Spacer()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
            .preferredColorScheme(.dark)
        }
        .onAppear { name = authService.currentUser?.displayName ?? "" }
    }
}

// MARK: - Upgrade Sheet (for guest -> account)
struct UpgradeSheet: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var email = ""; @State private var password = ""; @State private var name = ""
    @State private var showPass = false; @State private var isLoading = false; @State private var error: String?
    @State private var isFocusedE = false; @State private var isFocusedP = false; @State private var isFocusedN = false
    
    var body: some View {
        NavigationView {
            ZStack { AuthBackground(accentColor: HGColor.accent)
                ScrollView {
                    VStack(spacing: HGSpacing.xl) {
                        VStack(spacing: HGSpacing.md) {
                            AuthLogo()
                            VStack(spacing: 6) {
                                Text("Create Account").font(.system(size: 28, weight: .bold, design: .serif)).foregroundColor(HGColor.textPrimary)
                                Text("Save your data to the cloud and sync across devices").font(HGFont.body(14)).foregroundColor(HGColor.textSecondary).multilineTextAlignment(.center)
                            }
                        }.padding(.top, 40)
                        
                        VStack(spacing: HGSpacing.md) {
                            AuthTextField(placeholder: "Full name", text: $name, icon: "person.fill", isFocused: $isFocusedN)
                            AuthTextField(placeholder: "Email address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress, isFocused: $isFocusedE)
                            AuthSecureField(placeholder: "Password", text: $password, showPassword: $showPass, isFocused: $isFocusedP)
                            if let error = error { AuthErrorBanner(message: error) }
                            AuthPrimaryButton(title: "Create Account", isLoading: isLoading, gradient: HGColor.gradAccent) { signUp() }
                        }
                        
                        Spacer()
                    }.padding(.horizontal, HGSpacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(HGColor.textSecondary) } }
        }
    }
    private func signUp() {
        isLoading = true; error = nil
        Task {
            do {
                try await authService.signUp(email: email, password: password, name: name)
                await MainActor.run { dismiss() }
            } catch let e as AuthError { await MainActor.run { self.error = e.errorDescription; isLoading = false } }
            catch { await MainActor.run { self.error = error.localizedDescription; isLoading = false } }
        }
    }
}
