import Foundation
import LocalAuthentication

enum BiometricAuthManager {
    static func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw APIError.message("Biometria niedostępna na tym urządzeniu.")
        }
        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { ok, err in
                if ok {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: APIError.message(err?.localizedDescription ?? "Autoryzacja biometryczna nieudana."))
                }
            }
        }
    }
}
