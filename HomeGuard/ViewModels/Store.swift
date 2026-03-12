import Foundation
import Combine
import UIKit
import UserNotifications
import Network
import AppsFlyerLib

@MainActor
final class Store: ObservableObject {
    
    @Published var state: AppState = .initial
    
    private var timeoutTask: Task<Void, Never>?
    private var isLocked = false
    private let persistence: PersistenceLayer
    private let validator: Validator
    private let backend: Backend
    private let networkMonitor = NWPathMonitor()
    
    init(
        persistence: PersistenceLayer = DiskPersistence(),
        validator: Validator = FirebaseValidator(),
        backend: Backend = HTTPBackend()
    ) {
        self.persistence = persistence
        self.validator = validator
        self.backend = backend
        
        setupNetworkMonitor()
        loadConfig()
    }
    
    private func handleSideEffects(action: AppAction, oldState: AppState, newState: AppState) {
        switch action {
        case .initialize:
            scheduleTimeout()
            
        case .trackingReceived:
            persistence.saveTracking(newState.config.tracking.data)
            Task { await performValidation() }
            
        case .navigationReceived:
            persistence.saveNavigation(newState.config.navigation.data)
            
        case .validationSucceeded:
            Task { await executeBusinessLogic() }
            
        case .fetchAttributionSucceeded:
            persistence.saveTracking(newState.config.tracking.data)
            Task { await requestEndpoint() }
            
        case .fetchEndpointSucceeded(let endpoint):
            timeoutTask?.cancel()
            isLocked = true
            persistence.saveEndpoint(endpoint)
            persistence.saveMode("Active")
            persistence.markFirstLaunchDone()
            
        case .permissionRequested:
            requestNotificationPermission()
            
        case .permissionGranted:
            persistence.savePermissions(newState.config.permissions)
            UIApplication.shared.registerForRemoteNotifications()
            
        case .permissionDenied:
            persistence.savePermissions(newState.config.permissions)
            
        case .permissionDeferred:
            persistence.savePermissions(newState.config.permissions)
            
        default:
            break
        }
    }
    
    private func loadConfig() {
        let loaded = persistence.loadAll()
        
        let config = AppAction.ConfigData(
            mode: loaded.mode,
            firstLaunch: loaded.isFirstLaunch,
            tracking: loaded.tracking,
            navigation: loaded.navigation,
            permissions: AppAction.ConfigData.PermissionData(
                approved: loaded.permissions.approved,
                declined: loaded.permissions.declined,
                lastAsked: loaded.permissions.lastAsked
            )
        )
        
        dispatch(.configLoaded(config))
    }
    
    func dispatch(_ action: AppAction) {
        let oldState = state
        let newState = appReducer(state: oldState, action: action)
        state = newState
        
        handleSideEffects(action: action, oldState: oldState, newState: newState)
    }
    
    private func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isLocked else { return }
                if path.status == .satisfied {
                    self.dispatch(.networkOnline)
                } else {
                    self.dispatch(.networkOffline)
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    private func executeBusinessLogic() async {
        guard !isLocked else { return }
        
        guard state.config.tracking.isEmpty == false else {
            dispatch(.navigateToMain)
            return
        }
        
        // Check temp_url shortcut
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            dispatch(.fetchEndpointSucceeded(temp))
            return
        }
        
        // Check organic first launch
        if state.config.tracking.isOrganic && state.config.firstLaunch {
            await runOrganicFlow()
            return
        }
        
        // Normal flow
        await requestEndpoint()
    }
    
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !isLocked else { return }
            await MainActor.run { self.dispatch(.timeout) }
        }
    }
    
    private func performValidation() async {
        guard !isLocked else { return }
        guard state.config.tracking.isEmpty == false else { return }
        
        dispatch(.validationStarted)
        
        do {
            let isValid = try await validator.validate()
            if isValid {
                dispatch(.validationSucceeded)
            } else {
                dispatch(.validationFailed)
            }
        } catch {
            dispatch(.validationFailed)
        }
    }
    
    private func requestEndpoint() async {
        guard !isLocked else { return }
        
        dispatch(.fetchEndpointStarted)
        
        do {
            let trackingDict = convertToAnyDict(state.config.tracking.data)
            let endpoint = try await backend.fetchEndpoint(tracking: trackingDict)
            dispatch(.fetchEndpointSucceeded(endpoint))
        } catch {
            dispatch(.fetchEndpointFailed)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                if granted {
                    self?.dispatch(.permissionGranted)
                } else {
                    self?.dispatch(.permissionDenied)
                }
            }
        }
    }
    
    private func runOrganicFlow() async {
        guard !isLocked else { return }
        
        // 5 second delay
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        dispatch(.fetchAttributionStarted)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            var fetched = try await backend.fetchAttribution(deviceID: deviceID)
            
            // Merge with navigation
            let navigationDict = convertToAnyDict(state.config.navigation.data)
            for (key, value) in navigationDict {
                if fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            dispatch(.fetchAttributionSucceeded(fetched))
        } catch {
            dispatch(.fetchAttributionFailed)
        }
    }
    
    private func convertToAnyDict(_ dict: [String: String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = value
        }
        return result
    }
}
