import Foundation

struct PatientProfileResponse: Decodable {
    let status: String
    let patient: PatientProfile?
    let message: String?
}

struct PatientProfile: Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let pesel: String
    let address: String?
    let allergies: String?
    let chronicDiseases: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case pesel
        case address
        case allergies
        case chronicDiseases = "chronic_diseases"
    }
}
