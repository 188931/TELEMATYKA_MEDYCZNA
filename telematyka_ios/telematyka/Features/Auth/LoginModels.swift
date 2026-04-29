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
}

struct LoginUser: Decodable {
    let username: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case username
        case fullName = "full_name"
    }
}
