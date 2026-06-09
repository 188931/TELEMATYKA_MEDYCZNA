import Foundation

enum AuthTokenStore {
    private static let key = "auth_access_token"

    static func save(_ token: String) {
        UserDefaults.standard.set(token, forKey: key)
    }

    static func load() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
