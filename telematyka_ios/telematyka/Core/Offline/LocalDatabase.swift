import Foundation

actor LocalDatabase {
    struct State: Codable {
        var patients: [DebugPatient]
        var visits: [DebugVisit]
        var measurements: [DebugMeasurement]
        var doseCalculations: [DebugDoseCalculation]
        var photos: [DebugPhoto]
        var pending: [PendingMutation]

        init(
            patients: [DebugPatient],
            visits: [DebugVisit],
            measurements: [DebugMeasurement],
            doseCalculations: [DebugDoseCalculation] = [],
            photos: [DebugPhoto] = [],
            pending: [PendingMutation] = []
        ) {
            self.patients = patients
            self.visits = visits
            self.measurements = measurements
            self.doseCalculations = doseCalculations
            self.photos = photos
            self.pending = pending
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            patients = try container.decode([DebugPatient].self, forKey: .patients)
            visits = try container.decode([DebugVisit].self, forKey: .visits)
            measurements = try container.decode([DebugMeasurement].self, forKey: .measurements)
            doseCalculations = try container.decodeIfPresent([DebugDoseCalculation].self, forKey: .doseCalculations) ?? []
            photos = try container.decodeIfPresent([DebugPhoto].self, forKey: .photos) ?? []
            pending = try container.decodeIfPresent([PendingMutation].self, forKey: .pending) ?? []
        }
    }

    enum PendingMutation: Codable {
        case saveMeasurements(MeasurementPayload)
        case createVisit(NextVisitPayload)
        case updateVisit(UpdateVisitPayload)
        case doseCalculate(DoseCalculateRequest)
        case updateCoordinates(PatientCoordinatesPayload)
        case uploadPhoto(PendingPhotoUpload)
        case createPatient(CreatePatientPayload)
    }

    private let fileURL: URL
    private var state: State

    init(filename: String = "local-db.json") {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = base.appendingPathComponent(filename)
        state = Self.load(from: fileURL) ?? State(
            patients: DebugSeed.patients,
            visits: DebugSeed.scheduledVisits(for: Date()),
            measurements: DebugSeed.measurements,
            doseCalculations: DebugSeed.doseCalculations,
            photos: DebugSeed.photos,
            pending: []
        )
    }

    func snapshot() -> State { state }

    func update(_ mutate: (inout State) -> Void) {
        mutate(&state)
        persist()
    }

    private static func load(from url: URL) -> State? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        let data = (try? SecureFileStore.decrypt(raw)) ?? raw
        return try? JSONDecoder().decode(State.self, from: data)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state),
              let encrypted = try? SecureFileStore.encrypt(data) else { return }
        try? encrypted.write(to: fileURL, options: .atomic)
    }
}
