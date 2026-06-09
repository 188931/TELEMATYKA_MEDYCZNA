import SwiftUI

struct NursePatientCard: View {
    let patient: PatientVisit
    @ObservedObject var viewModel: AppViewModel

    private var isLocked: Bool { patient.isStartLocked }

    private var cardLabel: String {
        "Pacjent \(patient.fullName), wizyta \(patient.visitDate), status \(patient.visitStartStatusLabel)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(patient.fullName).font(.headline)
                    Text("Wizyta: \(patient.visitDate)").font(.subheadline)
                    AccessibleStatusBadge(
                        text: patient.visitStartStatusLabel,
                        systemImage: isLocked ? "lock.fill" : "lock.open.fill",
                        isPositive: !isLocked
                    )
                }
            }
            HStack {
                Button("Edytuj termin", systemImage: "calendar.badge.clock") {
                    viewModel.openReschedule(for: patient)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .minimumTapTarget()
                .accessibilityHint("Zmienia datę i godzinę wizyty")

                Button("Szczegóły", systemImage: "person.text.rectangle") {
                    viewModel.openPatientDetails(for: patient, asNurse: true)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.large)
                .minimumTapTarget()
                .accessibilityHint("Otwiera kartotekę pacjenta")

                Spacer()
                Button("Rozpocznij wizytę") { viewModel.openVisit(for: patient) }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLocked)
                    .controlSize(.large)
                    .minimumTapTarget()
                    .accessibilityHint(isLocked ? "Niedostępne przed godziną wizyty" : "Otwiera formularz pomiarów")
            }
            .accessibilityElement(children: .contain)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardLabel)
        .accessibilityHint("Użyj przycisków, aby zarządzać wizytą")
    }
}
