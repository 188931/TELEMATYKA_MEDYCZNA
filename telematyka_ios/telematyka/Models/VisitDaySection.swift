import Foundation

struct VisitDaySection: Identifiable {
    let id: String
    let dayTitle: String
    let visits: [PatientVisit]

    static func build(from visits: [PatientVisit]) -> [VisitDaySection] {
        let sorted = visits.sorted {
            ($0.parsedVisitDate ?? .distantFuture) < ($1.parsedVisitDate ?? .distantFuture)
        }
        var grouped: [String: [PatientVisit]] = [:]
        var dayOrder: [String] = []

        for visit in sorted {
            if grouped[visit.dayKey] == nil { dayOrder.append(visit.dayKey) }
            grouped[visit.dayKey, default: []].append(visit)
        }

        return dayOrder.map { key in
            let rows = (grouped[key] ?? []).sorted {
                ($0.parsedVisitDate ?? .distantFuture) < ($1.parsedVisitDate ?? .distantFuture)
            }
            return VisitDaySection(id: key, dayTitle: rows.first?.displayDay ?? key, visits: rows)
        }
    }
}
