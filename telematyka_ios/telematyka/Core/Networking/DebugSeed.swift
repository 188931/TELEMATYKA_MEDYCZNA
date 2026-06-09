import Foundation

enum DebugSeed {
    nonisolated(unsafe) static let patients: [DebugPatient] = [
        .init(id: 1, firstName: "Jan", lastName: "Kowalski", pesel: "90010112345", address: "Warszawa, ul. Marszałkowska 100", allergies: "Penicylina", chronicDiseases: "Nadciśnienie", latitude: 52.2290, longitude: 21.0120),
        .init(id: 2, firstName: "Anna", lastName: "Nowak", pesel: "92020254321", address: "Warszawa, ul. Puławska 12", allergies: "Brak", chronicDiseases: "Cukrzyca typu 2", latitude: 52.1980, longitude: 21.0230),
        .init(id: 3, firstName: "Maria", lastName: "Wiśniewska", pesel: "85030311223", address: "Warszawa, ul. Sobieskiego 88", allergies: "Lateks", chronicDiseases: "Astma", latitude: 52.1750, longitude: 21.0450),
        .init(id: 4, firstName: "Piotr", lastName: "Zieliński", pesel: "78121233445", address: "Warszawa, ul. Wolska 45", allergies: "Brak", chronicDiseases: "Choroba wieńcowa", latitude: 52.2340, longitude: 20.9650),
        .init(id: 5, firstName: "Ewa", lastName: "Kamińska", pesel: "95050566778", address: "Warszawa, ul. Francuska 3", allergies: "Aspiryna", chronicDiseases: "Osteoporoza", latitude: 52.2420, longitude: 21.0580)
    ]

    nonisolated(unsafe) static let measurements: [DebugMeasurement] = []

    nonisolated(unsafe) static let doseCalculations: [DebugDoseCalculation] = []
    nonisolated(unsafe) static let photos: [DebugPhoto] = []

    static func scheduledVisits(for day: Date) -> [DebugVisit] {
        let calendar = Calendar.current
        let slots: [(Int, Int, Int)] = [
            (100, 1, 9), (101, 2, 11), (102, 3, 13), (103, 4, 15), (104, 5, 17)
        ]
        return slots.compactMap { visitID, patientID, hour in
            guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else { return nil }
            return DebugVisit(
                id: visitID,
                patientID: patientID,
                visitDate: VisitDateFormatter.string(from: date)
            )
        }
    }
}

struct DebugPatient: Codable {
    var id: Int
    var firstName: String
    var lastName: String
    var pesel: String
    var address: String
    var allergies: String
    var chronicDiseases: String
    var latitude: Double?
    var longitude: Double?

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
    var temperature: Double?
    var weight: Double?
    var spo2: Int?
}

struct DebugDoseCalculation: Codable, Identifiable {
    var id: Int
    var patientID: Int
    var visitID: Int?
    var drugName: String
    var dosePerKgMg: Double
    var weightKg: Double
    var calculatedDoseMg: Double
    var allergyWarning: String?
    var createdAt: String
}

struct DebugPhoto: Codable, Identifiable {
    var id: Int
    var patientID: Int
    var visitID: Int?
    var fileName: String
    var caption: String?
    var takenAt: String
    var localDataBase64: String?
}
