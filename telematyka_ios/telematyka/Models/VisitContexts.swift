import Foundation

struct VisitMeasurementForm {
    var systolic = ""
    var diastolic = ""
    var heartRate = ""
    var glucose = ""
    var notes = ""

    var isValid: Bool {
        !systolic.isEmpty && !diastolic.isEmpty && !heartRate.isEmpty
    }
}

struct VisitContext: Identifiable {
    let id = UUID()
    let patient: PatientVisit
}

struct RescheduleContext: Identifiable {
    let id = UUID()
    let visitID: Int
    let currentDate: String
}

struct ScheduleNextContext: Identifiable {
    let id = UUID()
    let patientID: Int
    let patientName: String
}
