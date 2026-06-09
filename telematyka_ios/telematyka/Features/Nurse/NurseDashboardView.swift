import SwiftUI

struct NurseDashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        TabView(selection: $viewModel.nurseSelectedTab) {
            NurseVisitsTabView(viewModel: viewModel)
                .tabItem { Label("Wizyty", systemImage: "calendar") }
                .tag(0)
                .accessibilityLabel("Zakładka Wizyty")

            NursePatientsTabView(viewModel: viewModel)
                .tabItem { Label("Pacjenci", systemImage: "person.3") }
                .tag(1)
                .accessibilityLabel("Zakładka Pacjenci")

            RouteMapView(viewModel: viewModel)
                .tabItem { Label("Trasa", systemImage: "map") }
                .tag(2)
                .accessibilityLabel("Zakładka Trasa")
        }
        .accessibleLoading(viewModel.isLoading, label: "Ładowanie danych pielęgniarki")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Profil") {
                        Label(viewModel.signedInDisplayName, systemImage: "person.crop.circle")
                        Label(viewModel.signedInRoleLabel, systemImage: "stethoscope")
                    }
                    Button(role: .destructive) {
                        viewModel.logout()
                    } label: {
                        Label("Wyloguj", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .accessibleToolbarAction(
                    "Menu profilu",
                    hint: "Pokazuje nazwę użytkownika i opcję wylogowania"
                )
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await viewModel.refreshPatients() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibleToolbarAction(
                    "Odśwież listę",
                    hint: "Pobiera najnowsze dane pacjentów i wizyt"
                )
            }
        }
        .task {
            if viewModel.patients.isEmpty { await viewModel.refreshPatients() }
        }
    }
}
