import Foundation

enum DebugSeed {
    nonisolated(unsafe) static let patients: [DebugPatient] = [
        .init(id: 1, firstName: "Jan", lastName: "Kowalski", pesel: "90010112345", address: "Warszawa, Kwiatowa 1", allergies: "Penicylina", chronicDiseases: "Nadciśnienie"),
        .init(id: 2, firstName: "Anna", lastName: "Nowak", pesel: "92020254321", address: "Kraków, Leśna 12", allergies: "Brak", chronicDiseases: "Cukrzyca typu 2")
    ]

    nonisolated(unsafe) static let visits: [DebugVisit] = [
        .init(id: 100, patientID: 1, visitDate: "2026-04-27 10:00:00"),
        .init(id: 101, patientID: 2, visitDate: "2026-04-29 14:30:00")
    ]

    nonisolated(unsafe) static let measurements: [DebugMeasurement] = [
        .init(visitID: 100, sys: 132, dia: 85, hr: 72, glucose: 96.0, notes: "Stan stabilny")
    ]
}

struct DebugPatient: Codable {
    var id: Int
    var firstName: String
    var lastName: String
    var pesel: String
    var address: String
    var allergies: String
    var chronicDiseases: String

    var fullName: String { "\(firstName) \(lastName)" }
}

struct DebugVisit: Codable {
    var id: Int
    var patientID: Int
    var visitDate: String
}

struct DebugMeasurement: Codable {
    var visitID: Int
    var sys: Int
    var dia: Int
    var hr: Int
    var glucose: Double
    var notes: String
}
