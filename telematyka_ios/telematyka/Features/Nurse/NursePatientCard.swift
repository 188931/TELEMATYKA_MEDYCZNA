import SwiftUI

struct NursePatientCard: View {
    let patient: PatientVisit
    @ObservedObject var viewModel: AppViewModel

    private var isLocked: Bool { patient.isStartLocked }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .foregroundStyle(isLocked ? .red : .green)
                VStack(alignment: .leading) {
                    Text(patient.fullName).font(.headline)
                    Text("Wizyta: \(patient.visitDate)").font(.subheadline)
                    Text("Status: \(patient.visitStartStatusLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Button("Edytuj termin", systemImage: "calendar.badge.clock") {
                    viewModel.openReschedule(for: patient)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Szczegóły", systemImage: "person.text.rectangle") {
                    viewModel.openPatientDetails(for: patient, asNurse: true)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.large)
                Spacer()
                Button("Rozpocznij wizytę") { viewModel.openVisit(for: patient) }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLocked)
                    .controlSize(.large)
            }
        }
        .padding(.vertical, 6)
    }
}
