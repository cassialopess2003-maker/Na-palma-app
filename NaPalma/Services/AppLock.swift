import Foundation
import LocalAuthentication
import Observation

/// Face ID / Touch ID lock (falls back to the device passcode).
@MainActor
@Observable
final class AppLock {
    nonisolated static let storageKey = "appLockEnabled"

    var isLocked: Bool
    private var isAuthenticating = false

    init(locked: Bool) {
        self.isLocked = locked
    }

    static var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    static var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return String(localized: "Passcode")
        }
    }

    static var biometrySymbol: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .faceID: return "faceid"
        default: return "lock.fill"
        }
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await authenticate(reason: String(localized: "Unlock to see your finances")) {
            isLocked = false
        }
    }
}
