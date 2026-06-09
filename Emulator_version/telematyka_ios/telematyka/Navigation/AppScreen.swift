import Foundation

enum AppScreen {
    case welcome
    case nurseDashboard
    case patientPortal(pesel: String, fullName: String, isNurse: Bool)

    var isWelcome: Bool {
        if case .welcome = self { return true }
        return false
    }

    var navigationTitle: String {
        switch self {
        case .welcome:
            return "Aplikacja wspomagania pielęgniarki środowiskowej"
        case .nurseDashboard:
            return "Mobilna Pielęgniarka"
        case .patientPortal(_, let fullName, _):
            return "Portal Pacjenta - \(fullName)"
        }
    }
}
