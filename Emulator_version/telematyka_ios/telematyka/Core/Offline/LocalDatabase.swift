import Foundation

actor LocalDatabase {
    struct State: Codable {
        var patients: [DebugPatient]
        var visits: [DebugVisit]
        var measurements: [DebugMeasurement]
        var pending: [PendingMutation]
    }

    enum PendingMutation: Codable {
        case saveMeasurements(MeasurementPayload)
        case createVisit(NextVisitPayload)
        case updateVisit(UpdateVisitPayload)
    }

    private let fileURL: URL
    private var state: State

    init(filename: String = "local-db.json") {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = base.appendingPathComponent(filename)
        state = Self.load(from: fileURL) ?? State(
            patients: DebugSeed.patients,
            visits: DebugSeed.visits,
            measurements: DebugSeed.measurements,
            pending: []
        )
    }

    func snapshot() -> State { state }

    func update(_ mutate: (inout State) -> Void) {
        mutate(&state)
        persist()
    }

    private static func load(from url: URL) -> State? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(State.self, from: data)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
