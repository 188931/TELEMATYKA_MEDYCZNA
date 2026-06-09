import Foundation

struct VisitDaySection: Identifiable {
    let id: String
    let dayTitle: String
    let visits: [PatientVisit]

    static func build(from visits: [PatientVisit]) -> [VisitDaySection] {
        let ordered = visits.sorted(by: isHigherPriority)
        var grouped: [String: [PatientVisit]] = [:]
        var dayOrder: [String] = []

        for visit in ordered {
            if grouped[visit.dayKey] == nil { dayOrder.append(visit.dayKey) }
            grouped[visit.dayKey, default: []].append(visit)
        }

        return dayOrder.map { key in
            let rows = grouped[key] ?? []
            return VisitDaySection(id: key, dayTitle: rows.first?.displayDay ?? key, visits: rows)
        }
    }

    private static func isHigherPriority(_ lhs: PatientVisit, _ rhs: PatientVisit) -> Bool {
        let now = Date()
        let left = lhs.parsedVisitDate ?? .distantPast
        let right = rhs.parsedVisitDate ?? .distantPast

        let leftDelta = left.timeIntervalSince(now)
        let rightDelta = right.timeIntervalSince(now)

        let leftIsFuture = leftDelta >= 0
        let rightIsFuture = rightDelta >= 0

        if leftIsFuture && rightIsFuture { return leftDelta < rightDelta } // next first
        if !leftIsFuture && !rightIsFuture { return left > right } // recent past first
        return leftIsFuture // all future above past
    }
}
