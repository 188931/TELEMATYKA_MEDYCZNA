import Foundation

extension AppViewModel {
    func fetchTodayRoute() async throws -> [RouteStop] {
        if isDebugBackendEnabled {
            return await localServer.todayRoute()
        }
        return try await client.request(path: "/visits/today-route/")
    }

    func updatePatientCoordinates(patientID: Int, latitude: Double, longitude: Double) async throws {
        let payload = PatientCoordinatesPayload(patientID: patientID, latitude: latitude, longitude: longitude)
        if isDebugBackendEnabled {
            try await localServer.updateCoordinates(patientID: patientID, payload: payload)
            return
        }
        try await client.requestWithoutResponse(
            path: payload.path,
            method: "PUT",
            body: CoordinatesBody(latitude: latitude, longitude: longitude)
        )
    }
}

private struct CoordinatesBody: Codable {
    let latitude: Double
    let longitude: Double
}
