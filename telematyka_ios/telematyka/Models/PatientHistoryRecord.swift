import Foundation

struct PatientHistoryRecord: Decodable, Identifiable {
    let id = UUID()
    let patientID: Int?
    let visitDate: String
    let bloodPressureSys: Int
    let bloodPressureDia: Int
    let heartRate: Int
    let glucoseLevel: Double
    let notes: String
    let temperatureC: Double?
    let weightKg: Double?
    let spo2Percent: Int?
    let address: String?
    let allergies: String?
    let chronicDiseases: String?

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"
        case visitDate = "visit_date"
        case bloodPressureSys = "blood_pressure_sys"
        case bloodPressureDia = "blood_pressure_dia"
        case heartRate = "heart_rate"
        case glucoseLevel = "glucose_level"
        case notes
        case temperatureC = "temperature_c"
        case weightKg = "weight_kg"
        case spo2Percent = "spo2_percent"
        case address
        case allergies
        case chronicDiseases = "chronic_diseases"
    }
}
