import Foundation

extension DebugLocalServer {
    func syncPending(to api: APIClient) async {
        let pending = await db.snapshot().pending
        guard !pending.isEmpty else { return }
        var remaining = pending

        for mutation in pending {
            do {
                switch mutation {
                case .saveMeasurements(let payload):
                    try await api.requestWithoutResponse(path: "/measurements/", method: "POST", body: payload)
                case .createVisit(let payload):
                    try await api.requestWithoutResponse(path: "/create-visit/", method: "POST", body: payload)
                case .updateVisit(let payload):
                    try await api.requestWithoutResponse(path: "/update-visit-date/", method: "PUT", body: payload)
                }
                _ = remaining.removeFirst()
            } catch {
                break
            }
        }

        await db.update { $0.pending = remaining }
    }
}
