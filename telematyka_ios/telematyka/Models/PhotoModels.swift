import Foundation

struct PatientPhotoRecord: Decodable, Identifiable {
    let id: Int
    let patientID: Int
    let visitID: Int?
    let fileName: String
    let caption: String?
    let takenAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case patientID = "patient_id"
        case visitID = "visit_id"
        case fileName = "file_name"
        case caption
        case takenAt = "taken_at"
    }
}

struct PhotoUploadResponse: Decodable {
    let status: String
    let fileName: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case fileName = "file_name"
        case message
    }
}

struct PendingPhotoUpload: Codable {
    let patientID: Int
    let visitID: Int?
    let caption: String?
    let fileName: String
    let imageDataBase64: String
}

struct PhotoCaptureContext: Identifiable, Equatable {
    let id = UUID()
    let patientID: Int
    let visitID: Int?
}
