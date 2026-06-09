import Foundation

struct RouteStop: Decodable, Identifiable {
    let patientID: Int
    let firstName: String
    let lastName: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let visitID: Int
    let visitDate: String

    var id: Int { visitID }

    enum CodingKeys: String, CodingKey {
        case patientID = "id"
        case firstName = "first_name"
        case lastName = "last_name"
        case address
        case latitude
        case longitude
        case visitID = "visit_id"
        case visitDate = "visit_date"
    }

    var fullName: String { "\(firstName) \(lastName)" }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}

struct PatientCoordinatesPayload: Codable {
    let patientID: Int
    let latitude: Double
    let longitude: Double

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"
        case latitude
        case longitude
    }

    var path: String { "/patients/\(patientID)/coordinates/" }
}
