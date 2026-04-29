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
                    SecureField("Hasło", text: $password)
                } header: {
                    Text("Dane logowania · \(role.displayName)")
                } footer: {
                    if role == .patient {
                        Text("Demo: patient / patient123")
                            .font(.caption)
                    }
                }

                if viewModel.hasQuickSignIn(for: role) {
                    Section {
                        Button {
                            Task { await viewModel.quickSignIn(for: role) }
                        } label: {
                            Label("Zaloguj biometrią (Face ID / Touch ID)", systemImage: "faceid")
                        }
                    } header: {
                        Text("Zapisane na urządzeniu")
                    } footer: {
                        Text("Użyj biometrii dla ostatnio zapisanego konta w tej roli.")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Logowanie")
                        .font(.headline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onAppear {
                guard role == .patient else { return }
                if username.isEmpty { username = "patient" }
                if password.isEmpty { password = "patient123" }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeLoginRole = nil }
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
                }
            }
        }
    }
}
