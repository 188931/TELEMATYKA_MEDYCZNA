import Foundation

extension AppViewModel {
    func openDoseCalculator(for visit: PatientVisit) {
        Task {
            let weight = await localServer.latestWeight(for: visit.patientID)
            let allergies = await localServer.patientAllergies(patientID: visit.patientID)
            activeDoseCalculatorContext = DoseCalculatorContext(
                patientID: visit.patientID,
                patientName: visit.fullName,
                visitID: visit.visitID,
                defaultWeightKg: weight,
                allergies: allergies
            )
        }
    }

    func openDoseCalculator(patientID: Int, patientName: String, allergies: String?) {
        Task {
            let weight = await localServer.latestWeight(for: patientID)
            activeDoseCalculatorContext = DoseCalculatorContext(
                patientID: patientID,
                patientName: patientName,
                visitID: nil,
                defaultWeightKg: weight,
                allergies: allergies
            )
        }
    }

    func calculateDose(request: DoseCalculateRequest) async throws -> DoseCalculateResponse {
        if isDebugBackendEnabled {
            return try await localServer.calculateDose(request)
        }
        return try await client.request(path: "/dose-calculate/", method: "POST", body: request)
    }

    func fetchDoseHistory(patientID: Int) async throws -> [DoseHistoryRecord] {
        if isDebugBackendEnabled {
            return await localServer.doseHistory(patientID: patientID)
        }
        return try await client.request(path: "/patients/\(patientID)/dose-history/")
    }
}
