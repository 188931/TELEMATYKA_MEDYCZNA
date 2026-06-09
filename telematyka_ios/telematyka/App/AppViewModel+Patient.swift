import Foundation

extension AppViewModel {
    func fetchPatientHistory(pesel: String) async throws -> [PatientHistoryRecord] {
        if isDebugBackendEnabled {
            return await localServer.patientHistory(pesel: pesel)
        }
        return try await client.request(path: "/patient-history/\(pesel)")
    }

    func fetchPatientProfile(pesel: String) async throws -> PatientProfile? {
        if isDebugBackendEnabled {
            guard let patient = await localServer.allPatients().first(where: { $0.pesel == pesel }) else { return nil }
            return PatientProfile(
                id: patient.id,
                firstName: patient.firstName,
                lastName: patient.lastName,
                pesel: patient.pesel,
                address: patient.address,
                allergies: patient.allergies,
                chronicDiseases: patient.chronicDiseases
            )
        }
        let response: PatientProfileResponse = try await client.request(path: "/patient-profile/\(pesel)")
        return response.patient
    }

    func createPatient(payload: CreatePatientPayload) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if isDebugBackendEnabled {
                try await localServer.createPatient(payload)
            } else {
                let response: CreatePatientResponse = try await client.request(
                    path: "/patients/",
                    method: "POST",
                    body: payload
                )
                guard response.status == "success" else {
                    throw APIError.message(response.message ?? "Nie udało się dodać pacjenta.")
                }
            }
            activeAddPatientContext = false
            await refreshPatients()
        } catch {
            showError(error.localizedDescription)
        }
    }
}
