import SwiftUI

struct VisitFormSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: VisitContext
    @State private var form = VisitMeasurementForm()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ciśnienie skurczowe (mmHg) *", text: $form.systolic).keyboardType(.numberPad)
                TextField("Ciśnienie rozkurczowe (mmHg) *", text: $form.diastolic).keyboardType(.numberPad)
                TextField("Tętno (bpm) *", text: $form.heartRate).keyboardType(.numberPad)
                TextField("Glikemia (mg/dL)", text: $form.glucose).keyboardType(.decimalPad)
                TextField("Notatki z wizyty", text: $form.notes, axis: .vertical).lineLimit(3...6)
                Text("* pola wymagane")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Wizyta: \(context.patient.fullName)")
                        .font(.headline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.55)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeVisitContext = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz parametry") {
                        Task { await viewModel.submitMeasurements(context: context, form: form) }
                    }
                }
            }
        }
    }
}
