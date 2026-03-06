import Foundation
import Combine

// MARK: - Auth User Model
struct HGUser: Codable {
    var uid: String
    var email: String?
    var displayName: String?
    var isGuest: Bool
    var createdAt: Date
    var avatarColorIndex: Int
    
    init(uid: String, email: String? = nil, displayName: String? = nil, isGuest: Bool = false) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.isGuest = isGuest
        self.createdAt = Date()
        self.avatarColorIndex = Int.random(in: 0...5)
    }
    
    var initials: String {
        if let name = displayName, !name.isEmpty {
            let parts = name.split(separator: " ")
            return parts.prefix(2).compactMap { $0.first }.map { String($0) }.joined().uppercased()
        }
        if let email = email, !email.isEmpty {
            return String(email.prefix(2)).uppercased()
        }
        return "G"
    }
    
    var avatarColors: [Color] {
        let palettes: [[Color]] = [
            [Color(hex: "#F5A623"), Color(hex: "#FF7B4C")],
            [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")],
            [Color(hex: "#FF4C6A"), Color(hex: "#C62A47")],
            [Color(hex: "#23D18B"), Color(hex: "#16A96D")],
            [Color(hex: "#7B61FF"), Color(hex: "#5A42CC")],
            [Color(hex: "#F093FB"), Color(hex: "#F5576C")],
        ]
        return palettes[avatarColorIndex % palettes.count]
    }
}

import SwiftUI

// MARK: - Auth State
enum AuthState {
    case unknown
    case authenticated(HGUser)
    case unauthenticated
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailInUse
    case wrongPassword
    case userNotFound
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:    return "Please enter a valid email address."
        case .weakPassword:    return "Password must be at least 6 characters."
        case .emailInUse:      return "This email is already registered. Try signing in."
        case .wrongPassword:   return "Incorrect password. Please try again."
        case .userNotFound:    return "No account found with this email."
        case .networkError:    return "Network error. Check your connection."
        case .unknown(let m):  return m
        }
    }
}

// MARK: - Firebase Auth Service
// NOTE: This service uses Firebase Auth SDK.
// In Xcode, add Firebase iOS SDK via SPM: https://github.com/firebase/firebase-ios-sdk
// Then enable FirebaseAuth in your Firebase Console project.
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var authState: AuthState = .unknown
    @Published var currentUser: HGUser?
    @Published var isLoading = false
    
    private let userDefaultsKey = "homeguard.currentUser"
    
    private init() {
        loadPersistedUser()
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        try validateSignUp(email: email, password: password)
        
        // Firebase Auth call:
        // let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // let changeRequest = result.user.createProfileChangeRequest()
        // changeRequest.displayName = name
        // try await changeRequest.commitChanges()
        
        // Simulated for build:
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let uid = "user_\(UUID().uuidString.prefix(8))"
        let user = HGUser(uid: uid, email: email, displayName: name.isEmpty ? email.components(separatedBy: "@").first : name, isGuest: false)
        
        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.persistUser(user)
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        guard isValidEmail(email) else { throw AuthError.invalidEmail }
        guard !password.isEmpty else { throw AuthError.wrongPassword }
        
        // Firebase Auth call:
        // let result = try await Auth.auth().signIn(withEmail: email, password: password)
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let uid = "user_\(UUID().uuidString.prefix(8))"
        let user = HGUser(uid: uid, email: email, displayName: email.components(separatedBy: "@").first, isGuest: false)
        
        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.persistUser(user)
        }
    }
    
    // MARK: - Guest Mode
    func signInAsGuest() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        // Firebase anonymous sign in:
        // let result = try await Auth.auth().signInAnonymously()
        
        try? await Task.sleep(nanoseconds: 600_000_000)
        let uid = "guest_\(UUID().uuidString.prefix(8))"
        let user = HGUser(uid: uid, email: nil, displayName: "Guest", isGuest: true)
        
        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.persistUser(user)
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        // try Auth.auth().signOut()
        clearUser()
        authState = .unauthenticated
        currentUser = nil
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        
        // try await Auth.auth().currentUser?.delete()
        
        try await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
            self.clearUser()
            self.authState = .unauthenticated
            self.currentUser = nil
        }
    }
    
    // MARK: - Reset Password
    func sendPasswordReset(email: String) async throws {
        guard isValidEmail(email) else { throw AuthError.invalidEmail }
        // try await Auth.auth().sendPasswordReset(withEmail: email)
        try await Task.sleep(nanoseconds: 800_000_000)
    }
    
    // MARK: - Update Profile
    func updateProfile(name: String) async throws {
        guard var user = currentUser else { return }
        // let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        // changeRequest?.displayName = name
        // try await changeRequest?.commitChanges()
        user.displayName = name
        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.persistUser(user)
        }
    }
    
    // MARK: - Validation
    private func validateSignUp(email: String, password: String) throws {
        guard isValidEmail(email) else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    // MARK: - Persistence
    private func persistUser(_ user: HGUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadPersistedUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(HGUser.self, from: data) {
            currentUser = user
            authState = .authenticated(user)
        } else {
            authState = .unauthenticated
        }
    }
    
    private func clearUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
