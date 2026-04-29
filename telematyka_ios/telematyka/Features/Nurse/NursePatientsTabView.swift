import SwiftUI

struct NursePatientsTabView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        if viewModel.nursePatients.isEmpty && !viewModel.isLoading {
            ContentUnavailableView("Brak pacjentów", systemImage: "person.crop.circle.badge.xmark")
        } else {
            List(viewModel.nursePatients) { patient in
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
            }
            .listStyle(.plain)
        }
    }
}
