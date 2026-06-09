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
                .accessibleHeading()
                .accessibilityAddTraits(.isStaticText)

            Spacer(minLength: 0)

            VStack(spacing: 20) {
                if !showLoginSelection, viewModel.hasDeviceSignedInAccount() {
                    biometricSection
                } else {
                    RoleCard(
                        title: "Panel Pielęgniarki",
                        icon: "cross.case.fill",
                        color: .blue,
                        hint: "Otwiera logowanie do panelu pielęgniarki"
                    ) { viewModel.openLogin(for: .nurse) }

                    RoleCard(
                        title: "Portal Pacjenta",
                        icon: "person.fill",
                        color: .green,
                        hint: "Otwiera logowanie do portalu pacjenta"
                    ) { viewModel.openLogin(for: .patient) }
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .contain)
    }

    private var biometricSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 46))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .accessibleDecorativeImage()

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
                .accessibilityLabel("Zapisana rola: \(viewModel.deviceSignedInAccountRoleLabel())")

            Button {
                Task { await viewModel.quickSignInWithStoredAccount() }
            } label: {
                Label("Zaloguj biometrią", systemImage: "faceid")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .minimumTapTarget()
            .accessibilityHint("Uwierzytelnia za pomocą Face ID lub Touch ID")

            Button {
                showLoginSelection = true
            } label: {
                Text("Inne konto")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .minimumTapTarget()
            .accessibilityHint("Pokazuje wybór roli i logowanie innym kontem")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }
}

private struct RoleCard: View {
    let title: String
    let icon: String
    let color: Color
    let hint: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundStyle(color)
                .accessibleDecorativeImage()
            Text(title)
                .font(.headline)
                .accessibleHeading()
            Button("Wybierz", action: action)
                .buttonStyle(.borderedProminent)
                .minimumTapTarget()
                .accessibilityLabel("Wybierz: \(title)")
                .accessibilityHint(hint)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }
}
