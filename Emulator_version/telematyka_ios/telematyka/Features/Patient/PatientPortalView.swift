import SwiftUI

struct PatientPortalView: View {
    @ObservedObject var viewModel: AppViewModel
    let pesel: String
    let fullName: String
    let isNurse: Bool

    @State private var history: [PatientHistoryRecord] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                portalHeader
                patientInfoCard
                historySection
            }
            .padding()
        }
        .overlay { if isLoading { ProgressView("Ładowanie...") } }
        .task(id: pesel) { await loadHistory() }
    }
}

private extension PatientPortalView {
    var portalHeader: some View {
        HStack {
            Button {
                isNurse ? viewModel.returnToNurseDashboard() : viewModel.logout()
            } label: {
                Label(
                    isNurse ? "Wróć do listy pacjentów" : "Wyloguj",
                    systemImage: isNurse ? "arrow.left" : "rectangle.portrait.and.arrow.right"
                )
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    var patientInfoCard: some View {
        let profile = history.first
        return VStack(alignment: .leading, spacing: 8) {
            Text("Dane pacjenta").font(.title3).bold()
            Divider()
            Text("Pacjent: \(fullName)")
            Text("PESEL: \(pesel)")
            Text("Adres: \(profile?.address ?? "Brak danych")")
            Text("Alergie: \(profile?.allergies ?? "Brak")").foregroundStyle(.red)
            Text("Choroby przewlekłe: \(profile?.chronicDiseases ?? "Brak")")
            Divider()
            Text("Aktualny stan").font(.headline)
            Text("Ciśnienie: \(profile.map { "\($0.bloodPressureSys)/\($0.bloodPressureDia) mmHg" } ?? "-")")
            Text("Tętno: \(profile.map { "\($0.heartRate) bpm" } ?? "-")")
            Text("Glikemia: \(profile.map { "\($0.glucoseLevel) mg/dL" } ?? "-")")
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Historia pomiarów").font(.title3).bold()
            ForEach(history) { HistoryCard(item: $0) }
            if history.isEmpty && !isLoading {
                ContentUnavailableView("Brak historii", systemImage: "doc.text.magnifyingglass")
            }
        }
    }

    func loadHistory() async {
        guard !pesel.isEmpty else { history = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            history = try await viewModel.fetchPatientHistory(pesel: pesel)
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }
}

private struct HistoryCard: View {
    let item: PatientHistoryRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.visitDate).font(.headline)
            Text("Ciśnienie: \(item.bloodPressureSys)/\(item.bloodPressureDia) mmHg")
            Text("Tętno: \(item.heartRate) bpm")
            Text("Cukier: \(item.glucoseLevel) mg/dL")
            Text("Notatki: \(item.notes.isEmpty ? "-" : item.notes)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
