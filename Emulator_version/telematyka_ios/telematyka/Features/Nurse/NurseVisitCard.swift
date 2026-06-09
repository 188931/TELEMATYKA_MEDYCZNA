import SwiftUI

struct NurseVisitCard: View {
    let visit: PatientVisit
    @ObservedObject var viewModel: AppViewModel

    private var isLocked: Bool { visit.isStartLocked }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: big hour + patient summary
            HStack(alignment: .top, spacing: 12) {
                Text(visit.displayHour)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 112, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundStyle(isLocked ? .red : .green)
                        Text(visit.fullName)
                            .font(.headline)
                    }
                    Text(visit.visitStartStatusLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            // Row 2: left icon actions + right start
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    Button {
                        viewModel.openReschedule(for: visit)
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        viewModel.openPatientDetails(for: visit, asNurse: true)
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.large)
                }

                Spacer(minLength: 0)

                Button {
                    viewModel.openVisit(for: visit)
                } label: {
                    Text("Start")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLocked)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
