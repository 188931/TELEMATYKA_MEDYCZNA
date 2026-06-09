import Foundation

extension AppViewModel {
    func openPhotoCapture(patientID: Int, visitID: Int?) {
        activePhotoCaptureContext = PhotoCaptureContext(patientID: patientID, visitID: visitID)
    }

    func uploadPatientPhoto(patientID: Int, visitID: Int?, caption: String?, imageData: Data) async throws -> PatientPhotoRecord {
        if isDebugBackendEnabled {
            return try await localServer.savePhoto(
                patientID: patientID,
                visitID: visitID,
                caption: caption,
                imageData: imageData
            )
        }
        let response: PhotoUploadResponse = try await client.uploadMultipart(
            path: "/patients/\(patientID)/photos/",
            imageData: imageData,
            fileName: "photo.jpg",
            fields: [
                "visit_id": visitID.map(String.init),
                "caption": caption
            ]
        )
        guard response.status == "success", let fileName = response.fileName else {
            throw APIError.message(response.message ?? "Nie udało się zapisać zdjęcia.")
        }
        return PatientPhotoRecord(
            id: 0,
            patientID: patientID,
            visitID: visitID,
            fileName: fileName,
            caption: caption,
            takenAt: VisitDateFormatter.stringFromDate(Date(), format: "yyyy-MM-dd HH:mm:ss")
        )
    }

    func fetchPatientPhotos(patientID: Int) async throws -> [PatientPhotoRecord] {
        if isDebugBackendEnabled {
            return await localServer.patientPhotos(patientID: patientID)
        }
        return try await client.request(path: "/patients/\(patientID)/photos/")
    }

    func photoURL(fileName: String) -> URL {
        client.baseURL.appendingPathComponent("photos/\(fileName)")
    }

    func localPhotoData(fileName: String) async -> Data? {
        await localServer.photoData(fileName: fileName)
    }
}
