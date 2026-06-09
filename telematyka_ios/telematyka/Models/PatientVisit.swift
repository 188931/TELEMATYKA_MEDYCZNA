import Foundation

struct PatientVisit: Decodable, Identifiable {
    let patientID: Int
    let firstName: String
    let lastName: String
    let pesel: String?
    let visitID: Int
    let visitDate: String
    let address: String?
    let latitude: Double?
    let longitude: Double?

    var id: Int { visitID }

    enum CodingKeys: String, CodingKey {
        case patientID = "id"
        case firstName = "first_name"
        case lastName = "last_name"
        case pesel
        case visitID = "visit_id"
        case visitDate = "visit_date"
        case address
        case latitude
        case longitude
    }

    var fullName: String { "\(firstName) \(lastName)" }

    var parsedVisitDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: visitDate)
    }

    var dayKey: String {
        guard let parsedVisitDate else { return visitDate }
        return VisitDateFormatter.stringFromDate(parsedVisitDate, format: "yyyy-MM-dd")
    }

    var displayDay: String {
        guard let parsedVisitDate else { return visitDate }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: parsedVisitDate)
        let diffDays = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        if diffDays == 0 { return "Dziś" }
        if diffDays == 1 { return "Jutro" }

        // For the next days show weekday name (e.g. "Środa") for faster scanning.
        if diffDays > 1 && diffDays <= 6 {
            let df = DateFormatter()
            df.locale = Locale(identifier: "pl_PL")
            df.dateFormat = "EEEE"
            return df.string(from: parsedVisitDate)
        }

        return VisitDateFormatter.stringFromDate(parsedVisitDate, format: "dd.MM.yyyy")
    }

    var displayHour: String {
        guard let parsedVisitDate else { return "--:--" }
        return VisitDateFormatter.stringFromDate(parsedVisitDate, format: "HH:mm")
    }

    /// Visit falls on a calendar day before the reference date.
    func isPastCalendarDayVisit(relativeTo reference: Date = Date()) -> Bool {
        guard let parsedVisitDate else { return false }
        let cal = Calendar.current
        return cal.startOfDay(for: parsedVisitDate) < cal.startOfDay(for: reference)
    }

    var isPastCalendarDayVisit: Bool {
        isPastCalendarDayVisit(relativeTo: Date())
    }

    /// Locked only when scheduled time is still in the future.
    var isStartLocked: Bool {
        guard let visitDate = parsedVisitDate else { return true }
        return Date() < visitDate
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var visitStartStatusLabel: String {
        guard let visitDate = parsedVisitDate else { return "Brak terminu" }
        if Date() < visitDate {
            return isPastCalendarDayVisit ? "Zaległa — czeka na godzinę" : "Oczekuje"
        }
        if isPastCalendarDayVisit { return "Zaległa — można rozpocząć" }
        return "Można rozpocząć"
    }
}
