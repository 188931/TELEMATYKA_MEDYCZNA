import SwiftUI

struct VisitFormSheet: View {
    @ObservedObject var viewModel: AppViewModel
    let context: VisitContext
    @State private var form = VisitMeasurementForm()
    @State private var showBPEmulator = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Ciśnienie skurczowe (mmHg) *", text: $form.systolic)
                            .keyboardType(.numberPad)
                        Spacer()
                        Button {
                            showBPEmulator = true
                        } label: {
                            Label("Zmierz", systemImage: "waveform.path.ecg")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                    }
                    TextField("Ciśnienie rozkurczowe (mmHg) *", text: $form.diastolic)
                        .keyboardType(.numberPad)
                    TextField("Tętno (bpm) *", text: $form.heartRate)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Ciśnienie i tętno")
                } footer: {
                    Text("Naciśnij Zmierz aby uruchomić emulator ciśnieniomierza.")
                        .font(.caption)
                }

                Section("Pozostałe parametry") {
                    TextField("Glikemia (mg/dL)", text: $form.glucose)
                        .keyboardType(.decimalPad)
                    TextField("Notatki z wizyty", text: $form.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

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
            .sheet(isPresented: $showBPEmulator) {
                BPEmulatorSheet(
                    onResult: { sys, dia, hr in
                        // Wpisz wynik do pól formularza i zamknij emulator
                        form.systolic  = "\(sys)"
                        form.diastolic = "\(dia)"
                        form.heartRate = "\(hr)"
                        showBPEmulator = false
                    },
                    onCancel: {
                        showBPEmulator = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}