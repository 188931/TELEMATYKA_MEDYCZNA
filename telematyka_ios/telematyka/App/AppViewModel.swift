import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    @Published var activeLoginRole: UserRole?
    @Published var activeVisitContext: VisitContext?
    @Published var activeRescheduleContext: RescheduleContext?
    @Published var activeScheduleNextContext: ScheduleNextContext?
    @Published var patients: [PatientVisit] = []
    @Published var nursePatients: [NursePatient] = []
    @Published var signedInDisplayName = "Gość"
    @Published var signedInRoleLabel = "Brak sesji"
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isLoading = false

    private let api = APIClient(baseURL: URL(string: "http://127.0.0.1:8000")!)
    private let debugServer = DebugLocalServer()

    func openLogin(for role: UserRole) {
        activeLoginRole = role
    }

    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    func logout() {
        signedInDisplayName = "Gość"
        signedInRoleLabel = "Brak sesji"
        patients = []
        nursePatients = []
        activeLoginRole = nil
        QuickSignInStore.clear()
        currentScreen = .welcome
    }

    func returnToNurseDashboard() {
        currentScreen = .nurseDashboard
    }

    var client: APIClient { api }

    var isDebugBackendEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var localServer: DebugLocalServer { debugServer }
}
