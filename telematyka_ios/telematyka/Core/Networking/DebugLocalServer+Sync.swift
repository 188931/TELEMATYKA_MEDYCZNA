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
                case .doseCalculate(let payload):
                    let _: DoseCalculateResponse = try await api.request(path: "/dose-calculate/", method: "POST", body: payload)
                case .updateCoordinates(let payload):
                    try await api.requestWithoutResponse(
                        path: payload.path,
                        method: "PUT",
                        body: CoordinatesSyncBody(latitude: payload.latitude, longitude: payload.longitude)
                    )
                case .uploadPhoto(let payload):
                    guard let data = Data(base64Encoded: payload.imageDataBase64) else { continue }
                    let _: PhotoUploadResponse = try await api.uploadMultipart(
                        path: "/patients/\(payload.patientID)/photos/",
                        imageData: data,
                        fileName: payload.fileName,
                        fields: [
                            "visit_id": payload.visitID.map(String.init),
                            "caption": payload.caption
                        ]
                    )
                case .createPatient(let payload):
                    let _: CreatePatientResponse = try await api.request(
                        path: "/patients/",
                        method: "POST",
                        body: payload
                    )
                }
                _ = remaining.removeFirst()
            } catch {
                break
            }
        }

        await db.update { $0.pending = remaining }
    }
}

private struct CoordinatesSyncBody: Codable {
    let latitude: Double
    let longitude: Double
}
