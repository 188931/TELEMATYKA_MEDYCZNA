import SwiftUI

struct NursePatientsTabView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var searchText = ""

    private var filteredPatients: [NursePatient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return viewModel.nursePatients }
        return viewModel.nursePatients.filter {
            $0.fullName.lowercased().contains(query) || $0.pesel.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                if filteredPatients.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Brak pacjentów" : "Brak wyników",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text(searchText.isEmpty ? "Dodaj pierwszego pacjenta." : "Spróbuj innej frazy wyszukiwania.")
                    )
                    .accessibilityLabel(
                        searchText.isEmpty
                            ? "Brak pacjentów. Dodaj pierwszego pacjenta."
                            : "Brak wyników wyszukiwania. Spróbuj innej frazy."
                    )
                } else {
                    ForEach(filteredPatients) { patient in
                        Button {
                            viewModel.openPatientDetails(for: patient, asNurse: true)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(patient.fullName).font(.headline)
                                Text("PESEL: \(patient.pesel)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .minimumTapTarget()
                        .accessibilityLabel("Pacjent \(patient.fullName), PESEL \(patient.pesel)")
                        .accessibilityHint("Otwiera kartotekę pacjenta")
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Szukaj po imieniu, nazwisku lub PESEL")
            .accessibilityLabel("Wyszukiwarka pacjentów")
            .accessibilityHint("Filtruje listę po imieniu, nazwisku lub numerze PESEL")

            Button {
                viewModel.activeAddPatientContext = true
            } label: {
                Label("Dodaj pacjenta", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .minimumTapTarget()
            .padding()
            .background(.bar)
            .accessibilityHint("Otwiera formularz dodawania nowego pacjenta")
        }
    }
}
