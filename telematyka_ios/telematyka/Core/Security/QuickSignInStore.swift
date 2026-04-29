import Foundation

struct LastUsedAccount: Codable {
    let username: String
    let password: String
    let role: UserRole
}

enum QuickSignInStore {
    private static let key = "last-used-account"

    static func save(_ account: LastUsedAccount) {
        guard let data = try? JSONEncoder().encode(account) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> LastUsedAccount? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LastUsedAccount.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
