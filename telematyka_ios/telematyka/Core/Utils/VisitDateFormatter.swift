import Foundation

enum VisitDateFormatter {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func date(from raw: String) -> Date {
        formatter.date(from: raw) ?? Date()
    }

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func stringFromDate(_ date: Date, format: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = format
        return f.string(from: date)
    }
}
