import SwiftUI

struct LoginSheet: View {
    let role: UserRole
    @ObservedObject var viewModel: AppViewModel
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Login", text: $username)
                        .textInputAutocapitalization(.never)
                        .accessibleFormLabel("Login", required: true)
                        .textContentType(.username)
                    SecureField("Hasło", text: $password)
                        .accessibleFormLabel("Hasło", required: true)
                        .textContentType(.password)
                } header: {
                    Text("Dane logowania · \(role.displayName)")
                        .accessibleHeading()
                } footer: {
                    if role == .patient {
                        Text("Demo: patient / patient123")
                            .font(.caption)
                            .accessibilityLabel("Dane demonstracyjne: login patient, hasło patient123")
                    }
                }

                if viewModel.hasQuickSignIn(for: role) {
                    Section {
                        Button {
                            Task { await viewModel.quickSignIn(for: role) }
                        } label: {
                            Label("Zaloguj biometrią (Face ID / Touch ID)", systemImage: "faceid")
                        }
                        .minimumTapTarget()
                        .accessibilityHint("Uwierzytelnia zapisane konto biometrią")
                    } header: {
                        Text("Zapisane na urządzeniu")
                            .accessibleHeading()
                    } footer: {
                        Text("Użyj biometrii dla ostatnio zapisanego konta w tej roli.")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Logowanie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeLoginRole = nil }
                        .accessibilityHint("Zamyka ekran logowania bez zapisywania")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zaloguj") {
                        Task {
                            await viewModel.login(
                                username: username,
                                password: password,
                                role: role
                            )
                        }
                    }
                    .accessibilityHint("Wysyła dane logowania i otwiera aplikację")
                    .disabled(username.isEmpty || password.isEmpty)
                }
            }
        }
        .onAppear {
            guard role == .patient else { return }
            if username.isEmpty { username = "patient" }
            if password.isEmpty { password = "patient123" }
        }
    }
}
