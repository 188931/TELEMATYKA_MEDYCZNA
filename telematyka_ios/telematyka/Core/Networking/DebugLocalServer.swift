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
            return LoginResponse(
                status: "success",
                message: nil,
                user: .init(username: "nurse", fullName: "Pielęgniarka Demo"),
                accessToken: "debug-nurse-token"
            )
        }
        if request.username == demoPatientLogin, request.password == demoPatientPassword,
           let patient = snapshot.patients.first {
            return LoginResponse(
                status: "success",
                message: nil,
                user: .init(username: patient.pesel, fullName: patient.fullName),
                accessToken: "debug-patient-token"
            )
        }
        guard let patient = snapshot.patients.first(where: { $0.pesel == request.username }) else {
            throw APIError.message("Pacjent nie istnieje.")
        }
        return LoginResponse(
            status: "success",
            message: nil,
            user: .init(username: patient.pesel, fullName: patient.fullName),
            accessToken: "debug-patient-token"
        )
    }

    func patientsWithVisits() async -> [PatientVisit] {
        let snapshot = await db.snapshot()
        let completedVisitIDs = Set(snapshot.measurements.map(\.visitID))
        return snapshot.visits
            .filter { !completedVisitIDs.contains($0.id) }
            .compactMap { visit in
                guard let patient = snapshot.patients.first(where: { $0.id == visit.patientID }) else { return nil }
                return PatientVisit(
                    patientID: patient.id,
                    firstName: patient.firstName,
                    lastName: patient.lastName,
                    pesel: patient.pesel,
                    visitID: visit.id,
                    visitDate: visit.visitDate,
                    address: patient.address,
                    latitude: patient.latitude,
                    longitude: patient.longitude
                )
            }
    }

    func todayRoute() async -> [RouteStop] {
        let snapshot = await db.snapshot()
        let todayKey = VisitDateFormatter.stringFromDate(Date(), format: "yyyy-MM-dd")
        var matching = snapshot.visits.filter { $0.visitDate.hasPrefix(todayKey) }
        if matching.isEmpty { matching = snapshot.visits }
        return matching
            .sorted { $0.visitDate < $1.visitDate }
            .compactMap { visit -> RouteStop? in
                guard let patient = snapshot.patients.first(where: { $0.id == visit.patientID }) else { return nil }
                return RouteStop(
                    patientID: patient.id,
                    firstName: patient.firstName,
                    lastName: patient.lastName,
                    address: patient.address,
                    latitude: patient.latitude,
                    longitude: patient.longitude,
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
                notes: payload.notes,
                temperature: payload.temperatureC,
                weight: payload.weightKg,
                spo2: payload.spo2Percent
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
        return snapshot.measurements.filter { visitIDs.contains($0.visitID) }.map { item in
            let date = snapshot.visits.first(where: { $0.id == item.visitID })?.visitDate ?? "-"
            return PatientHistoryRecord(
                patientID: patient.id,
                visitDate: date,
                bloodPressureSys: item.sys,
                bloodPressureDia: item.dia,
                heartRate: item.hr,
                glucoseLevel: item.glucose,
                notes: item.notes,
                temperatureC: item.temperature,
                weightKg: item.weight,
                spo2Percent: item.spo2,
                address: patient.address,
                allergies: patient.allergies,
                chronicDiseases: patient.chronicDiseases
            )
        }
        .sorted { $0.visitDate > $1.visitDate }
    }

    func calculateDose(_ request: DoseCalculateRequest) async throws -> DoseCalculateResponse {
        let snapshot = await db.snapshot()
        guard let patient = snapshot.patients.first(where: { $0.id == request.patientID }) else {
            throw APIError.message("Pacjent nie istnieje.")
        }
        let calculated = (request.dosePerKgMg * request.weightKg * 100).rounded() / 100
        let warning = DoseCalculatorLogic.allergyWarning(drugName: request.drugName, allergies: patient.allergies)
        await db.update {
            let newID = ($0.doseCalculations.map(\.id).max() ?? 0) + 1
            $0.doseCalculations.append(.init(
                id: newID,
                patientID: request.patientID,
                visitID: request.visitID,
                drugName: request.drugName,
                dosePerKgMg: request.dosePerKgMg,
                weightKg: request.weightKg,
                calculatedDoseMg: calculated,
                allergyWarning: warning,
                createdAt: VisitDateFormatter.stringFromDate(Date(), format: "yyyy-MM-dd HH:mm:ss")
            ))
            $0.pending.append(.doseCalculate(request))
        }
        return DoseCalculateResponse(status: "success", calculatedDoseMg: calculated, allergyWarning: warning, message: nil)
    }

    func doseHistory(patientID: Int) async -> [DoseHistoryRecord] {
        let snapshot = await db.snapshot()
        return snapshot.doseCalculations
            .filter { $0.patientID == patientID }
            .sorted { $0.createdAt > $1.createdAt }
            .map {
                DoseHistoryRecord(
                    id: $0.id,
                    drugName: $0.drugName,
                    dosePerKgMg: $0.dosePerKgMg,
                    weightKg: $0.weightKg,
                    calculatedDoseMg: $0.calculatedDoseMg,
                    allergyWarning: $0.allergyWarning,
                    createdAt: $0.createdAt
                )
            }
    }

    func updateCoordinates(patientID: Int, payload: PatientCoordinatesPayload) async throws {
        let snapshot = await db.snapshot()
        guard let idx = snapshot.patients.firstIndex(where: { $0.id == patientID }) else {
            throw APIError.message("Pacjent nie istnieje.")
        }
        await db.update {
            $0.patients[idx].latitude = payload.latitude
            $0.patients[idx].longitude = payload.longitude
            $0.pending.append(.updateCoordinates(payload))
        }
    }

    func savePhoto(patientID: Int, visitID: Int?, caption: String?, imageData: Data) async throws -> PatientPhotoRecord {
        let fileName = "local_\(patientID)_\(UUID().uuidString).jpg"
        let base64 = imageData.base64EncodedString()
        let takenAt = VisitDateFormatter.stringFromDate(Date(), format: "yyyy-MM-dd HH:mm:ss")
        var record = PatientPhotoRecord(
            id: 0,
            patientID: patientID,
            visitID: visitID,
            fileName: fileName,
            caption: caption,
            takenAt: takenAt
        )
        await db.update {
            let newID = ($0.photos.map(\.id).max() ?? 0) + 1
            record = PatientPhotoRecord(
                id: newID,
                patientID: patientID,
                visitID: visitID,
                fileName: fileName,
                caption: caption,
                takenAt: takenAt
            )
            $0.photos.append(.init(
                id: newID,
                patientID: patientID,
                visitID: visitID,
                fileName: fileName,
                caption: caption,
                takenAt: takenAt,
                localDataBase64: base64
            ))
            $0.pending.append(.uploadPhoto(.init(
                patientID: patientID,
                visitID: visitID,
                caption: caption,
                fileName: fileName,
                imageDataBase64: base64
            )))
        }
        return record
    }

    func patientPhotos(patientID: Int) async -> [PatientPhotoRecord] {
        let snapshot = await db.snapshot()
        return snapshot.photos
            .filter { $0.patientID == patientID }
            .sorted { $0.takenAt > $1.takenAt }
            .map {
                PatientPhotoRecord(
                    id: $0.id,
                    patientID: $0.patientID,
                    visitID: $0.visitID,
                    fileName: $0.fileName,
                    caption: $0.caption,
                    takenAt: $0.takenAt
                )
            }
    }

    func photoData(fileName: String) async -> Data? {
        let snapshot = await db.snapshot()
        guard let photo = snapshot.photos.first(where: { $0.fileName == fileName }),
              let base64 = photo.localDataBase64 else { return nil }
        return Data(base64Encoded: base64)
    }

    func allPatients() async -> [DebugPatient] {
        await db.snapshot().patients
    }

    func createPatient(_ payload: CreatePatientPayload) async throws {
        let snapshot = await db.snapshot()
        if snapshot.patients.contains(where: { $0.pesel == payload.pesel }) {
            throw APIError.message("Pacjent z tym PESEL już istnieje.")
        }
        await db.update {
            let newPatientID = ($0.patients.map(\.id).max() ?? 0) + 1
            $0.patients.append(.init(
                id: newPatientID,
                firstName: payload.firstName,
                lastName: payload.lastName,
                pesel: payload.pesel,
                address: payload.address,
                allergies: payload.allergies,
                chronicDiseases: payload.chronicDiseases,
                latitude: nil,
                longitude: nil
            ))
            if let visitDate = payload.visitDate {
                let newVisitID = ($0.visits.map(\.id).max() ?? 0) + 1
                $0.visits.append(.init(id: newVisitID, patientID: newPatientID, visitDate: visitDate))
            }
            $0.pending.append(.createPatient(payload))
        }
    }

    func patientAllergies(patientID: Int) async -> String? {
        await db.snapshot().patients.first(where: { $0.id == patientID })?.allergies
    }

    func latestWeight(for patientID: Int) async -> Double? {
        let snapshot = await db.snapshot()
        let visitIDs = Set(snapshot.visits.filter { $0.patientID == patientID }.map(\.id))
        return snapshot.measurements
            .filter { visitIDs.contains($0.visitID) }
            .compactMap(\.weight)
            .last
    }
}
