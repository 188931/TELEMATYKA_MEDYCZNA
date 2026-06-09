import SwiftUI

struct RescheduleVisitSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: RescheduleContext
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Nowa data i godzina",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityHint("Wybierz nową datę i godzinę wizyty")
                } header: {
                    Text("Termin wizyty")
                        .accessibleHeading()
                }

                Section {
                    Button("Ustaw na teraz") {
                        selectedDate = Date()
                        Task { await save(date: Date()) }
                    }
                    .minimumTapTarget()
                    .accessibilityHint("Ustawia termin na bieżącą godzinę i zapisuje zmianę")
                } footer: {
                    Text("Użyj „Ustaw na teraz”, aby odblokować wizytę i rozpocząć pomiary natychmiast.")
                        .font(.caption)
                }

                Text("Zapis do API: \(VisitDateFormatter.string(from: selectedDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Wybrany termin: \(VisitDateFormatter.string(from: selectedDate))")
            }
            .navigationTitle("Zmiana terminu")
            .onAppear {
                selectedDate = VisitDateFormatter.date(from: context.currentDate)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeRescheduleContext = nil }
                        .accessibilityHint("Zamyka bez zapisywania zmian")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zaktualizuj") {
                        Task { await save(date: selectedDate) }
                    }
                    .accessibilityHint("Zapisuje nowy termin wizyty")
                }
            }
        }
    }

    private func save(date: Date) async {
        await viewModel.rescheduleVisit(
            context: context,
            newDate: VisitDateFormatter.string(from: date)
        )
    }
}
