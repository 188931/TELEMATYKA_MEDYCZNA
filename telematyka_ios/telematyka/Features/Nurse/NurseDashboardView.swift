import SwiftUI

struct NurseDashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NurseVisitsTabView(viewModel: viewModel)
                .tabItem { Label("Wizyty", systemImage: "calendar") }
                .tag(0)

            NursePatientsTabView(viewModel: viewModel)
                .tabItem { Label("Pacjenci", systemImage: "person.3") }
                .tag(1)
        }
        .overlay {
            if viewModel.isLoading { ProgressView("Ładowanie...") }
        }
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
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await viewModel.refreshPatients() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            if viewModel.patients.isEmpty { await viewModel.refreshPatients() }
        }
    }
}
