import Foundation

struct PatientHistoryRecord: Decodable, Identifiable {
    let id = UUID()
    let visitDate: String
    let bloodPressureSys: Int
    let bloodPressureDia: Int
    let heartRate: Int
    let glucoseLevel: Double
    let notes: String
    let address: String?
    let allergies: String?
    let chronicDiseases: String?

    enum CodingKeys: String, CodingKey {
        case visitDate = "visit_date"
        case bloodPressureSys = "blood_pressure_sys"
        case bloodPressureDia = "blood_pressure_dia"
        case heartRate = "heart_rate"
        case glucoseLevel = "glucose_level"
        case notes
        case address
        case allergies
        case chronicDiseases = "chronic_diseases"
    }
}
