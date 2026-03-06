import SwiftUI

// MARK: - Auth Root
struct AuthRootView: View {
    @State private var showSignUp = false
    @State private var showForgot = false
    
    var body: some View {
        ZStack {
            if showSignUp {
                SignUpView(showSignIn: { showSignUp = false })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                SignInView(
                    showSignUp: { withAnimation(.spring()) { showSignUp = true } },
                    showForgot: { showForgot = true }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showSignUp)
        .sheet(isPresented: $showForgot) {
            ForgotPasswordView()
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    let showSignUp: () -> Void
    let showForgot: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @State private var email     = ""
    @State private var password  = ""
    @State private var showPass  = false
    @State private var error: String?
    @State private var isLoading = false
    @State private var emailFocused = false
    @State private var passFocused  = false
    @State private var headerVisible = false
    @State private var formVisible   = false
    
    var body: some View {
        ZStack {
            AuthBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top decoration
                    AuthHeaderDecoration()
                        .opacity(headerVisible ? 1 : 0)
                        .offset(y: headerVisible ? 0 : -40)
                    
                    VStack(spacing: HGSpacing.xl) {
                        // Logo & title
                        VStack(spacing: HGSpacing.md) {
                            AuthLogo()
                            
                            VStack(spacing: 6) {
                                Text("Welcome Back")
                                    .font(.system(size: 32, weight: .bold, design: .serif))
                                    .foregroundColor(HGColor.textPrimary)
                                Text("Sign in to your fortress")
                                    .font(HGFont.body(15))
                                    .foregroundColor(HGColor.textSecondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: HGSpacing.md) {
                            AuthTextField(
                                placeholder: "Email address",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress,
                                isFocused: $emailFocused
                            )
                            
                            AuthSecureField(
                                placeholder: "Password",
                                text: $password,
                                showPassword: $showPass,
                                isFocused: $passFocused
                            )
                            
                            HStack {
                                Spacer()
                                Button(action: showForgot) {
                                    Text("Forgot password?")
                                        .font(HGFont.body(13, weight: .medium))
                                        .foregroundColor(HGColor.accent)
                                }
                            }
                        }
                        
                        // Error
                        if let error = error {
                            AuthErrorBanner(message: error)
                        }
                        
                        // Sign In button
                        AuthPrimaryButton(
                            title: "Sign In",
                            isLoading: isLoading,
                            gradient: HGColor.gradAccent
                        ) { signIn() }
                        
                        // Divider
                        AuthDivider(label: "or")
                        
                        // Guest mode
                        AuthGhostButton(
                            title: "Continue as Guest",
                            icon: "person.fill",
                            note: "Limited features • No sync"
                        ) { guestMode() }
                        
                        // Sign up link
                        HStack(spacing: 6) {
                            Text("Don't have an account?")
                                .font(HGFont.body(14))
                                .foregroundColor(HGColor.textSecondary)
                            Button(action: showSignUp) {
                                Text("Create one")
                                    .font(HGFont.body(14, weight: .bold))
                                    .foregroundColor(HGColor.accent)
                            }
                        }
                        .padding(.bottom, 60)
                    }
                    .padding(.horizontal, HGSpacing.lg)
                    .opacity(formVisible ? 1 : 0)
                    .offset(y: formVisible ? 0 : 30)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { headerVisible = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25)) { formVisible = true }
        }
    }
    
    private func signIn() {
        dismissKeyboard()
        isLoading = true
        error = nil
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch let e as AuthError {
                await MainActor.run { self.error = e.errorDescription; self.isLoading = false }
            } catch {
                await MainActor.run { self.error = "An unexpected error occurred."; self.isLoading = false }
            }
        }
    }
    
    private func guestMode() {
        Task { await authService.signInAsGuest() }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    let showSignIn: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @State private var name      = ""
    @State private var email     = ""
    @State private var password  = ""
    @State private var confirmPw = ""
    @State private var showPass  = false
    @State private var error: String?
    @State private var isLoading = false
    @State private var formVisible = false
    @State private var nameFocused  = false
    @State private var emailFocused = false
    @State private var passFocused  = false
    @State private var confFocused  = false
    
    var canSubmit: Bool {
        !name.isEmpty && authService.isValidEmail(email) && password.count >= 6 && password == confirmPw
    }
    
    var body: some View {
        ZStack {
            AuthBackground(accentColor: Color(hex: "#4ECDC4"))
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: HGSpacing.xl) {
                    
                    // Back + Title
                    HStack {
                        Button(action: showSignIn) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Sign In")
                                    .font(HGFont.body(14, weight: .medium))
                            }
                            .foregroundColor(HGColor.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.top, 60)
                    
                    VStack(spacing: 6) {
                        Text("Create Account")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundColor(HGColor.textPrimary)
                        Text("Build your home's digital passport")
                            .font(HGFont.body(15))
                            .foregroundColor(HGColor.textSecondary)
                    }
                    
                    // Password strength indicator
                    if !password.isEmpty {
                        PasswordStrengthBar(password: password)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Form
                    VStack(spacing: HGSpacing.md) {
                        AuthTextField(placeholder: "Full name", text: $name, icon: "person.fill", isFocused: $nameFocused)
                        AuthTextField(placeholder: "Email address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress, isFocused: $emailFocused)
                        AuthSecureField(placeholder: "Password (6+ chars)", text: $password, showPassword: $showPass, isFocused: $passFocused)
                        AuthSecureField(placeholder: "Confirm password", text: $confirmPw, showPassword: $showPass, isFocused: $confFocused)
                        
                        if !confirmPw.isEmpty && password != confirmPw {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(HGColor.danger)
                                Text("Passwords don't match")
                                    .font(HGFont.body(12))
                                    .foregroundColor(HGColor.danger)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    if let error = error {
                        AuthErrorBanner(message: error)
                    }
                    
                    AuthPrimaryButton(
                        title: "Create Account",
                        isLoading: isLoading,
                        gradient: HGColor.gradCool
                    ) { signUp() }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    
                    AuthDivider(label: "or")
                    
                    AuthGhostButton(title: "Continue as Guest", icon: "person.fill", note: "Try without an account") {
                        Task { await authService.signInAsGuest() }
                    }
                    
                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .font(HGFont.body(14))
                            .foregroundColor(HGColor.textSecondary)
                        Button(action: showSignIn) {
                            Text("Sign in")
                                .font(HGFont.body(14, weight: .bold))
                                .foregroundColor(Color(hex: "#4ECDC4"))
                        }
                    }
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, HGSpacing.lg)
                .opacity(formVisible ? 1 : 0)
                .offset(y: formVisible ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { formVisible = true }
        }
    }
    
    private func signUp() {
        dismissKeyboard()
        isLoading = true; error = nil
        Task {
            do {
                try await authService.signUp(email: email, password: password, name: name)
            } catch let e as AuthError {
                await MainActor.run { self.error = e.errorDescription; self.isLoading = false }
            } catch {
                await MainActor.run { self.error = "Something went wrong. Try again."; self.isLoading = false }
            }
        }
    }
}

// MARK: - Forgot Password
struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent  = false
    @State private var error: String?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            AuthBackground()
            VStack(spacing: HGSpacing.xl) {
                VStack(spacing: HGSpacing.md) {
                    ZStack {
                        Circle().fill(HGColor.accent.opacity(0.12)).frame(width: 80, height: 80)
                        Image(systemName: "key.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(HGColor.gradAccent)
                    }
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(HGColor.textPrimary)
                    Text("Enter your email and we'll send you a reset link.")
                        .font(HGFont.body(15))
                        .foregroundColor(HGColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                if sent {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(HGColor.success)
                        Text("Email sent!")
                            .font(HGFont.heading(20))
                            .foregroundColor(HGColor.textPrimary)
                        Text("Check your inbox for the reset link.")
                            .font(HGFont.body(14))
                            .foregroundColor(HGColor.textSecondary)
                    }
                } else {
                    VStack(spacing: HGSpacing.md) {
                        AuthTextField(placeholder: "Email address", text: $email, icon: "envelope.fill", keyboardType: .emailAddress, isFocused: .constant(false))
                        if let error = error { AuthErrorBanner(message: error) }
                        AuthPrimaryButton(title: "Send Reset Link", isLoading: isLoading, gradient: HGColor.gradAccent) { send() }
                    }
                }
                
                Button("Cancel") { dismiss() }
                    .foregroundColor(HGColor.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, HGSpacing.lg)
        }
    }
    
    private func send() {
        isLoading = true; error = nil
        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                await MainActor.run { sent = true; isLoading = false }
            } catch let e as AuthError {
                await MainActor.run { self.error = e.errorDescription; isLoading = false }
            }
        }
    }
}

// MARK: - Auth Sub-Components

struct AuthBackground: View {
    var accentColor: Color = Color(hex: "#F5A623")
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(hex: "#060D18").ignoresSafeArea()
            
            // Morphing blobs
            Circle()
                .fill(accentColor.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: animate ? 60 : 30, y: animate ? -200 : -180)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)
            
            Circle()
                .fill(Color(hex: "#4ECDC4").opacity(0.05))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: animate ? -50 : -80, y: animate ? 250 : 220)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)
            
            // Grid pattern
            AuthGridPattern()
                .opacity(0.04)
        }
        .onAppear { animate = true }
    }
}

struct AuthGridPattern: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 36
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    }, with: .color(.white), lineWidth: 0.3)
                    x += step
                }
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }, with: .color(.white), lineWidth: 0.3)
                y += step
            }
        }
        .ignoresSafeArea()
    }
}

struct AuthHeaderDecoration: View {
    var body: some View {
        ZStack {
            // Top glow line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(hex: "#F5A623").opacity(0.5), Color(hex: "#4ECDC4").opacity(0.3), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 40)
                .blur(radius: 2)
        }
        .padding(.top, 0)
    }
}

struct AuthLogo: View {
    var body: some View {
        ZStack {
            Circle().fill(HGColor.accent.opacity(0.1)).frame(width: 90, height: 90)
            Circle().fill(HGColor.accent.opacity(0.05)).frame(width: 110, height: 110)
            
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(hex: "#162A47"), Color(hex: "#0F1E35")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 72, height: 72)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(HGColor.glassBorder, lineWidth: 1))
                .hgShadow(HGShadow.accent)
            
            VStack(spacing: 0) {
                Image(systemName: "house.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(HGColor.gradAccent)
                Image(systemName: "shield.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(HGColor.gradCool)
                    .offset(y: -3)
            }
        }
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String
    var keyboardType: UIKeyboardType = .default
    @Binding var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isFocused ? HGColor.accent : HGColor.textTertiary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(HGColor.textTertiary))
                .font(HGFont.body(15))
                .foregroundColor(HGColor.textPrimary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, HGSpacing.md)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: HGRadius.md)
                .fill(isFocused ? HGColor.bg3 : HGColor.bg2)
                .overlay(
                    RoundedRectangle(cornerRadius: HGRadius.md)
                        .stroke(isFocused ? HGColor.accent : HGColor.glassBorder, lineWidth: isFocused ? 1.5 : 1)
                )
        )
        .hgShadow(isFocused ? HGShadow.accent : HGShadow.sm)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool
    @Binding var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
                .foregroundColor(isFocused ? HGColor.accent : HGColor.textTertiary)
                .frame(width: 20)
            
            Group {
                if showPassword {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(HGColor.textTertiary))
                } else {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(HGColor.textTertiary))
                }
            }
            .font(HGFont.body(15))
            .foregroundColor(HGColor.textPrimary)
            .autocapitalization(.none)
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 15))
                    .foregroundColor(HGColor.textTertiary)
            }
        }
        .padding(.horizontal, HGSpacing.md)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: HGRadius.md)
                .fill(isFocused ? HGColor.bg3 : HGColor.bg2)
                .overlay(
                    RoundedRectangle(cornerRadius: HGRadius.md)
                        .stroke(isFocused ? HGColor.accent : HGColor.glassBorder, lineWidth: isFocused ? 1.5 : 1)
                )
        )
        .hgShadow(isFocused ? HGShadow.accent : HGShadow.sm)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct AuthPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var gradient: LinearGradient = HGColor.gradAccent
    let action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: HGRadius.md)
                    .fill(gradient)
                    .frame(height: 54)
                    .hgShadow(HGShadow.accent)
                
                // Shine overlay
                RoundedRectangle(cornerRadius: HGRadius.md)
                    .fill(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 27)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .cornerRadius(HGRadius.md)
                    .frame(height: 54)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(HGFont.heading(16))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded { _ in pressed = false }
        )
        .disabled(isLoading)
    }
}

struct AuthGhostButton: View {
    let title: String
    let icon: String
    let note: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(HGColor.textSecondary)
                    Text(title)
                        .font(HGFont.heading(15))
                        .foregroundColor(HGColor.textSecondary)
                }
                Text(note)
                    .font(HGFont.body(11))
                    .foregroundColor(HGColor.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: HGRadius.md)
                    .fill(HGColor.bg2)
                    .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.glassBorder, lineWidth: 1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .pressAnimation()
    }
}

struct AuthDivider: View {
    let label: String
    var body: some View {
        HStack(spacing: HGSpacing.md) {
            Rectangle().fill(HGColor.glassBorder).frame(height: 1)
            Text(label).font(HGFont.body(12)).foregroundColor(HGColor.textTertiary)
            Rectangle().fill(HGColor.glassBorder).frame(height: 1)
        }
    }
}

struct AuthErrorBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(HGColor.danger)
            Text(message)
                .font(HGFont.body(13))
                .foregroundColor(HGColor.danger)
            Spacer()
        }
        .padding(HGSpacing.md)
        .background(HGColor.danger.opacity(0.1))
        .cornerRadius(HGRadius.md)
        .overlay(RoundedRectangle(cornerRadius: HGRadius.md).stroke(HGColor.danger.opacity(0.3), lineWidth: 1))
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }
}

struct PasswordStrengthBar: View {
    let password: String
    
    var strength: Int {
        var s = 0
        if password.count >= 8 { s += 1 }
        if password.count >= 12 { s += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { s += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { s += 1 }
        if password.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil { s += 1 }
        return min(s, 4)
    }
    
    var label: String {
        ["Too short", "Weak", "Fair", "Good", "Strong"][strength]
    }
    var color: Color {
        [HGColor.danger, HGColor.warning, Color(hex: "#F5A623"), HGColor.success, Color(hex: "#23D18B")][strength]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < strength ? color : HGColor.textMuted)
                        .frame(height: 4)
                        .animation(.spring(response: 0.3), value: strength)
                }
            }
            Text("Password strength: \(label)")
                .font(HGFont.body(11))
                .foregroundColor(color)
        }
    }
}

// MARK: - Keyboard helper
func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
