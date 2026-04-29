import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showLoginSelection = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            Text(AppScreen.welcome.navigationTitle)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(8)
                .minimumScaleFactor(0.55)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)

            Spacer(minLength: 0)

            VStack(spacing: 20) {
                if !showLoginSelection, viewModel.hasDeviceSignedInAccount() {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 46))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)

                        Text("Użyj Face ID / Touch ID, aby się zalogować.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Rola: \(viewModel.deviceSignedInAccountRoleLabel())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Button {
                            Task { await viewModel.quickSignInWithStoredAccount() }
                        } label: {
                            Label("Zaloguj biometrią", systemImage: "faceid")
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)

                        Button {
                            showLoginSelection = true
                        } label: {
                            Text("Inne konto")
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    RoleCard(
                        title: "Panel Pielęgniarki",
                        icon: "cross.case.fill",
                        color: .blue
                    ) { viewModel.openLogin(for: .nurse) }

                    RoleCard(
                        title: "Portal Pacjenta",
                        icon: "person.fill",
                        color: .green
                    ) { viewModel.openLogin(for: .patient) }
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct RoleCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 42)).foregroundStyle(color)
            Text(title).font(.headline)
            Button("Wybierz", action: action).buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
