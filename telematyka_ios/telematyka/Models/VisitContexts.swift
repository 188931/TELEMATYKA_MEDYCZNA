import Foundation

struct VisitMeasurementForm {
    var systolic = ""
    var diastolic = ""
    var heartRate = ""
    var glucose = ""
    var temperature = ""
    var weight = ""
    var spo2 = ""
    var notes = ""

    var isValid: Bool {
        !systolic.isEmpty && !diastolic.isEmpty && !heartRate.isEmpty
    }

    var temperatureValue: Double? {
        guard let value = Double(temperature.replacingOccurrences(of: ",", with: ".")) else { return nil }
        guard (34.0...42.0).contains(value) else { return nil }
        return value
    }

    var weightValue: Double? {
        guard let value = Double(weight.replacingOccurrences(of: ",", with: ".")) else { return nil }
        guard (20.0...300.0).contains(value) else { return nil }
        return value
    }

    var spo2Value: Int? {
        guard let value = Int(spo2) else { return nil }
        guard (70...100).contains(value) else { return nil }
        return value
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
