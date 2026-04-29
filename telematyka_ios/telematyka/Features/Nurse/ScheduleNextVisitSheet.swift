import SwiftUI

struct ScheduleNextVisitSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: ScheduleNextContext
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Text("Pacjent: \(context.patientName)")
                DatePicker(
                    "Data kolejnej wizyty",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                Text("Zapis do API: \(VisitDateFormatter.string(from: selectedDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Zaplanuj następną wizytę")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeScheduleNextContext = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zatwierdź termin") {
                        Task {
                            await viewModel.scheduleNextVisit(
                                context: context,
                                dateString: VisitDateFormatter.string(from: selectedDate)
                            )
                        }
                    }
                }
            }
        }
    }
}
