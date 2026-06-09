import Foundation

final class DebugLocalServer {
    private let demoPatientLogin = "patient"
    private let demoPatientPassword = "patient123"
    let db = LocalDatabase()

    func login(with request: LoginRequest) async throws -> LoginResponse {
        let snapshot = await db.snapshot()
        if request.role == UserRole.nurse.rawValue {
            guard request.username == "nurse", request.password == "nurse123" else {
                throw APIError.message("Błędny login lub hasło.")
            }
            return LoginResponse(status: "success", message: nil,
                                 user: .init(username: "nurse", fullName: "Pielęgniarka Demo"))
        }
        if request.username == demoPatientLogin, request.password == demoPatientPassword,
           let patient = snapshot.patients.first {
            return LoginResponse(status: "success", message: nil,
                                 user: .init(username: patient.pesel, fullName: patient.fullName))
        }
        guard let patient = snapshot.patients.first(where: { $0.pesel == request.username }) else {
            throw APIError.message("Pacjent nie istnieje.")
        }
        return LoginResponse(status: "success", message: nil,
                             user: .init(username: patient.pesel, fullName: patient.fullName))
    }

    func patientsWithVisits() async -> [PatientVisit] {
        let snapshot = await db.snapshot()
        return snapshot.visits.compactMap { visit in
            guard let patient = snapshot.patients.first(where: { $0.id == visit.patientID }) else { return nil }
            return PatientVisit(
                id: patient.id,
                firstName: patient.firstName,
                lastName: patient.lastName,
                pesel: patient.pesel,
                visitID: visit.id,
                visitDate: visit.visitDate
            )
        }
    }

    func saveMeasurements(_ payload: MeasurementPayload) async throws {
        let exists = await db.snapshot().visits.contains(where: { $0.id == payload.visitID })
        guard exists else { throw APIError.message("Wizyta nie istnieje.") }
        await db.update {
            $0.measurements.append(.init(
                visitID: payload.visitID,
                sys: payload.bloodPressureSys,
                dia: payload.bloodPressureDia,
                hr: payload.heartRate,
                glucose: payload.glucoseLevel,
                notes: payload.notes
            ))
            $0.pending.append(.saveMeasurements(payload))
        }
    }

    func createVisit(_ payload: NextVisitPayload) async throws {
        let snapshot = await db.snapshot()
        guard snapshot.patients.contains(where: { $0.id == payload.patientID }) else {
            throw APIError.message("Pacjent nie istnieje.")
        }
        await db.update {
            let newID = ($0.visits.map(\.id).max() ?? 0) + 1
            $0.visits.append(.init(id: newID, patientID: payload.patientID, visitDate: payload.visitDate))
            $0.pending.append(.createVisit(payload))
        }
    }

    func updateVisit(_ payload: UpdateVisitPayload) async throws {
        let snapshot = await db.snapshot()
        guard let idx = snapshot.visits.firstIndex(where: { $0.id == payload.visitID }) else {
            throw APIError.message("Wizyta nie istnieje.")
        }
        await db.update {
            $0.visits[idx].visitDate = payload.newDate
            $0.pending.append(.updateVisit(payload))
        }
    }

    func patientHistory(pesel: String) async -> [PatientHistoryRecord] {
        let snapshot = await db.snapshot()
        guard let patient = snapshot.patients.first(where: { $0.pesel == pesel }) else { return [] }
        let visitIDs = snapshot.visits.filter { $0.patientID == patient.id }.map(\.id)
        return snapshot.measurements
            .filter { visitIDs.contains($0.visitID) }
            .map { item in
                let date = snapshot.visits.first(where: { $0.id == item.visitID })?.visitDate ?? "-"
                return PatientHistoryRecord(
                    visitDate: date,
                    bloodPressureSys: item.sys,
                    bloodPressureDia: item.dia,
                    heartRate: item.hr,
                    glucoseLevel: item.glucose,
                    notes: item.notes,
                    address: patient.address,
                    allergies: patient.allergies,
                    chronicDiseases: patient.chronicDiseases
                )
            }
            .sorted { $0.visitDate > $1.visitDate }
    }

    func allPatients() async -> [DebugPatient] {
        await db.snapshot().patients
    }

    func simulateBloodPressure() -> [BPSimulationStep] {
        return BPSimulationStepGenerator.generate()
    }
}