import SwiftUI

struct ScheduleNextVisitSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: ScheduleNextContext
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Pacjent: \(context.patientName)")
                        .accessibilityLabel("Pacjent: \(context.patientName)")
                    DatePicker(
                        "Data kolejnej wizyty",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityHint("Wybierz datę i godzinę kolejnej wizyty")
                } header: {
                    Text("Planowanie")
                        .accessibleHeading()
                }

                Text("Zapis do API: \(VisitDateFormatter.string(from: selectedDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Wybrany termin: \(VisitDateFormatter.string(from: selectedDate))")
            }
            .navigationTitle("Zaplanuj następną wizytę")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeScheduleNextContext = nil }
                        .accessibilityHint("Zamyka bez planowania wizyty")
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
                    .accessibilityHint("Zapisuje zaplanowaną wizytę")
                }
            }
        }
    }
}
