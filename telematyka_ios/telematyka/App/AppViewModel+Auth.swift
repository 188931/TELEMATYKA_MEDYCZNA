import Foundation

extension AppViewModel {
    func login(username: String, password: String, role: UserRole) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let payload = LoginRequest(username: username, password: password, role: role.rawValue)
            let response: LoginResponse
            if isDebugBackendEnabled {
                response = try await localServer.login(with: payload)
            } else {
                response = try await client.request(
                    path: "/login/",
                    method: "POST",
                    body: payload
                )
            }

            guard response.status == "success", let user = response.user else {
                throw APIError.message(response.message ?? "Nieznany błąd logowania.")
            }

            QuickSignInStore.save(.init(username: username, password: password, role: role))
            activeLoginRole = nil
            if role == .nurse {
                signedInDisplayName = user.fullName
                signedInRoleLabel = "Pielęgniarka"
                currentScreen = .nurseDashboard
                await refreshPatients()
            } else {
                signedInDisplayName = user.fullName
                signedInRoleLabel = "Pacjent"
                currentScreen = .patientPortal(
                    pesel: user.username,
                    fullName: user.fullName,
                    isNurse: false
                )
            }
        } catch {
            showError(error.localizedDescription)
        }
    }

    func hasQuickSignIn(for role: UserRole) -> Bool {
        QuickSignInStore.load()?.role == role
    }

    func quickSignIn(for role: UserRole) async {
        guard let account = QuickSignInStore.load(), account.role == role else {
            return showError("Brak zapisanej sesji dla tej roli.")
        }
        do {
            try await BiometricAuthManager.authenticate(reason: "Szybkie logowanie")
            await login(username: account.username, password: account.password, role: account.role)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func hasDeviceSignedInAccount() -> Bool {
        QuickSignInStore.load() != nil
    }

    func deviceSignedInAccountRoleLabel() -> String {
        guard let role = QuickSignInStore.load()?.role else { return "Brak sesji" }
        return role == .nurse ? "Pielęgniarka" : "Pacjent"
    }

    func quickSignInWithStoredAccount() async {
        guard let account = QuickSignInStore.load() else {
            return showError("Brak zapisanej sesji na tym urządzeniu.")
        }
        do {
            try await BiometricAuthManager.authenticate(reason: "Szybkie logowanie")
            await login(username: account.username, password: account.password, role: account.role)
        } catch {
            showError(error.localizedDescription)
        }
    }
}
