import Foundation

struct NursePatient: Identifiable, Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let pesel: String

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case pesel
    }

    init(id: Int, fullName: String, pesel: String) {
        self.id = id
        let parts = fullName.split(separator: " ", maxSplits: 1).map(String.init)
        self.firstName = parts.first ?? fullName
        self.lastName = parts.count > 1 ? parts[1] : ""
        self.pesel = pesel
    }
}

struct CreatePatientPayload: Codable {
    let firstName: String
    let lastName: String
    let pesel: String
    let address: String
    let allergies: String
    let chronicDiseases: String
    let password: String
    let visitDate: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case pesel
        case address
        case allergies
        case chronicDiseases = "chronic_diseases"
        case password
        case visitDate = "visit_date"
    }
}

struct CreatePatientResponse: Decodable {
    let status: String
    let patientID: Int?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case patientID = "patient_id"
        case message
    }
}
