import SwiftUI

struct RescheduleVisitSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: RescheduleContext
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Nowa data i godzina",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                Text("Zapis do API: \(VisitDateFormatter.string(from: selectedDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Zmiana terminu")
            .onAppear {
                selectedDate = VisitDateFormatter.date(from: context.currentDate)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeRescheduleContext = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zaktualizuj") {
                        Task {
                            await viewModel.rescheduleVisit(
                                context: context,
                                newDate: VisitDateFormatter.string(from: selectedDate)
                            )
                        }
                    }
                }
            }
        }
    }
}
