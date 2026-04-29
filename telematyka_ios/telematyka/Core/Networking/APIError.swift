import Foundation

struct BackendErrorResponse: Decodable {
    let message: String?
}

enum APIError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text):
            return text
        }
    }
}
