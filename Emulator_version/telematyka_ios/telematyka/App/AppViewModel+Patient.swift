import Foundation

extension AppViewModel {
    func fetchPatientHistory(pesel: String) async throws -> [PatientHistoryRecord] {
        if isDebugBackendEnabled {
            return await localServer.patientHistory(pesel: pesel)
        }
        return try await client.request(path: "/patient-history/\(pesel)")
    }
}
