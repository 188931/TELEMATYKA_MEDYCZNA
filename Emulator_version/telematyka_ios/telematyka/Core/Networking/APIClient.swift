import Foundation

struct APIClient {
    let baseURL: URL
    private let decoder = JSONDecoder()

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        let request = try buildRequest(path: path, method: method, body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    func requestWithoutResponse(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws {
        let request = try buildRequest(path: path, method: method, body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }

    private func buildRequest(
        path: String,
        method: String,
        body: (any Encodable)?
    ) throws -> URLRequest {
        let suffix = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var request = URLRequest(url: baseURL.appendingPathComponent(suffix))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONEncoder().encode(AnyEncodable(body)) }
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.message("Nieprawidłowa odpowiedź serwera.")
        }
        guard (200...299).contains(http.statusCode) else {
            let backendError = try? decoder.decode(BackendErrorResponse.self, from: data)
            throw APIError.message(backendError?.message ?? "Błąd serwera: \(http.statusCode)")
        }
    }
}
