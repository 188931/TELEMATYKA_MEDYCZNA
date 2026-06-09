import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var currentScreen: AppScreen = .welcome
    @Published var activeLoginRole: UserRole?
    @Published var activeVisitContext: VisitContext?
    @Published var activeRescheduleContext: RescheduleContext?
    @Published var activeScheduleNextContext: ScheduleNextContext?
    @Published var activeDoseCalculatorContext: DoseCalculatorContext?
    @Published var activePhotoCaptureContext: PhotoCaptureContext?
    @Published var activeAddPatientContext = false
    @Published var patients: [PatientVisit] = []
    @Published var nursePatients: [NursePatient] = []
    @Published var signedInDisplayName = "Gość"
    @Published var signedInRoleLabel = "Brak sesji"
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var nurseSelectedTab = 0
    @Published var nurseReturnTab = 0

    private var api = APIClient(baseURL: URL(string: "http://127.0.0.1:8000")!, authToken: AuthTokenStore.load())
    private let debugServer = DebugLocalServer()

    func openLogin(for role: UserRole) {
        activeLoginRole = role
    }

    func setAuthToken(_ token: String?) {
        api.authToken = token
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
        AuthTokenStore.clear()
        setAuthToken(nil)
        currentScreen = .welcome
    }

    func returnToNurseDashboard() {
        nurseSelectedTab = nurseReturnTab
        currentScreen = .nurseDashboard
    }

    var client: APIClient {
        get { api }
        set { api = newValue }
    }

    var isDebugBackendEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var localServer: DebugLocalServer { debugServer }

    var nurseBackButtonTitle: String {
        switch nurseReturnTab {
        case 1: return "Wróć do listy pacjentów"
        case 2: return "Wróć do trasy"
        default: return "Wróć do harmonogramu"
        }
    }
}
