import SwiftUI

struct VisitFormSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: VisitContext
    @State private var form = VisitMeasurementForm()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Wizyta: \(context.patient.fullName)")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityAddTraits(.isHeader)
                }

                Section {
                    TextField("Ciśnienie skurczowe (mmHg) *", text: $form.systolic)
                        .keyboardType(.numberPad)
                        .accessibleFormLabel("Ciśnienie skurczowe w milimetrach słupa rtęci", required: true)
                    TextField("Ciśnienie rozkurczowe (mmHg) *", text: $form.diastolic)
                        .keyboardType(.numberPad)
                        .accessibleFormLabel("Ciśnienie rozkurczowe w milimetrach słupa rtęci", required: true)
                    TextField("Tętno (bpm) *", text: $form.heartRate)
                        .keyboardType(.numberPad)
                        .accessibleFormLabel("Tętno w uderzeniach na minutę", required: true)
                    TextField("Temperatura (°C)", text: $form.temperature)
                        .keyboardType(.decimalPad)
                        .accessibleFormLabel("Temperatura w stopniach Celsjusza")
                    TextField("Waga (kg)", text: $form.weight)
                        .keyboardType(.decimalPad)
                        .accessibleFormLabel("Waga w kilogramach")
                    TextField("SpO2 (%)", text: $form.spo2)
                        .keyboardType(.numberPad)
                        .accessibleFormLabel("Saturacja krwi w procentach")
                    TextField("Glikemia (mg/dL)", text: $form.glucose)
                        .keyboardType(.decimalPad)
                        .accessibleFormLabel("Poziom glukozy w miligramach na decylitr")
                    TextField("Notatki z wizyty", text: $form.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibleFormLabel("Notatki z wizyty")
                } header: {
                    Text("Parametry życiowe")
                        .accessibleHeading()
                }

                Section {
                    Button {
                        // Placeholder — integracja z urządzeniami w przyszłej wersji.
                    } label: {
                        Label("Zczytaj z urządzeń", systemImage: "waveform.path.ecg")
                    }
                    .minimumTapTarget()
                    .accessibilityHint("Funkcja w przygotowaniu — odczyt z urządzeń medycznych")
                } header: {
                    Text("Urządzenia medyczne")
                        .accessibleHeading()
                }

                Section {
                    Button {
                        viewModel.openPhotoCapture(
                            patientID: context.patient.patientID,
                            visitID: context.patient.visitID
                        )
                    } label: {
                        Label("Dodaj zdjęcie pacjenta", systemImage: "camera.fill")
                    }
                    .minimumTapTarget()
                    .accessibilityHint("Otwiera aparat lub galerię")
                } header: {
                    Text("Zdjęcie z wizyty")
                        .accessibleHeading()
                }

                Text(AccessibleTheme.requiredHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(AccessibleTheme.requiredHint)
            }
            .navigationTitle("Rejestracja wizyty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeVisitContext = nil }
                        .accessibilityHint("Zamyka formularz bez zapisywania pomiarów")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz parametry") {
                        Task { await viewModel.submitMeasurements(context: context, form: form) }
                    }
                    .accessibilityHint("Zapisuje wprowadzone parametry życiowe")
                }
            }
        }
    }
}
