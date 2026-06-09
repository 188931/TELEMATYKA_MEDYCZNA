import Foundation

struct MeasurementPayload: Codable {
    let visitID: Int
    let bloodPressureSys: Int
    let bloodPressureDia: Int
    let heartRate: Int
    let glucoseLevel: Double
    let notes: String

    enum CodingKeys: String, CodingKey {
        case visitID = "visit_id"
        case bloodPressureSys = "blood_pressure_sys"
        case bloodPressureDia = "blood_pressure_dia"
        case heartRate = "heart_rate"
        case glucoseLevel = "glucose_level"
        case notes
    }
}

struct NextVisitPayload: Codable {
    let patientID: Int
    let visitDate: String

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"
        case visitDate = "visit_date"
    }
}

struct UpdateVisitPayload: Codable {
    let visitID: Int
    let newDate: String

    enum CodingKeys: String, CodingKey {
        case visitID = "visit_id"
        case newDate = "new_date"
    }
}
