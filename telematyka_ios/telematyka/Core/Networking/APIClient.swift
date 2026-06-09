import Foundation

struct APIClient {
    let baseURL: URL
    var authToken: String?
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

    func uploadMultipart<T: Decodable>(
        path: String,
        imageData: Data,
        fileName: String,
        fields: [String: String?]
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: buildURL(path: path))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        for (key, value) in fields {
            guard let value else { continue }
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func buildURL(path: String) -> URL {
        let suffix = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent(suffix)
    }

    private func buildRequest(
        path: String,
        method: String,
        body: (any Encodable)?
    ) throws -> URLRequest {
        var request = URLRequest(url: buildURL(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
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

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
