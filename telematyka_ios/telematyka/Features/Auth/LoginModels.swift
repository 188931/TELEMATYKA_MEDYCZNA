import Foundation

enum UserRole: String, Identifiable, Codable {
    case nurse
    case patient

    var id: String { rawValue }
    var displayName: String { self == .nurse ? "Pielęgniarka" : "Pacjent" }
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
    let role: String
}

struct LoginResponse: Decodable {
    let status: String
    let message: String?
    let user: LoginUser?
    let accessToken: String?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case user
        case accessToken = "access_token"
    }

    init(status: String, message: String?, user: LoginUser?, accessToken: String? = nil) {
        self.status = status
        self.message = message
        self.user = user
        self.accessToken = accessToken
    }
}

struct LoginUser: Decodable {
    let username: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
    }
}
