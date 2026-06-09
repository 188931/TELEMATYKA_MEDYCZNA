import SwiftUI

struct DoseCalculatorView: View {
    @ObservedObject var viewModel: AppViewModel
    let context: DoseCalculatorContext

    @State private var drugName = ""
    @State private var dosePerKg = ""
    @State private var weight = ""
    @State private var result: DoseCalculateResponse?
    @State private var history: [DoseHistoryRecord] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                if let allergies = context.allergies, !allergies.isEmpty, allergies.lowercased() != "brak" {
                    Section {
                        AccessibleWarningText(text: "Alergie: \(allergies)")
                    } header: {
                        Text("Alergie pacjenta")
                            .accessibleHeading()
                    }
                }

                Section {
                    TextField("Nazwa leku", text: $drugName)
                        .accessibleFormLabel("Nazwa leku", required: true)
                    TextField("Dawka (mg/kg)", text: $dosePerKg).keyboardType(.decimalPad)
                        .accessibleFormLabel("Dawka w miligramach na kilogram", required: true)
                    TextField("Waga pacjenta (kg)", text: $weight).keyboardType(.decimalPad)
                        .accessibleFormLabel("Waga pacjenta w kilogramach", required: true)
                } header: {
                    Text("Dane do obliczenia")
                        .accessibleHeading()
                }

                Section {
                    Button("Oblicz dawkę") {
                        Task { await calculate() }
                    }
                    .disabled(!canCalculate)
                    .minimumTapTarget()
                    .accessibilityHint(canCalculate ? "Oblicza dawkę leku" : "Uzupełnij wszystkie pola numeryczne")
                }

                if let result {
                    Section {
                        if let dose = result.calculatedDoseMg {
                            Text("Obliczona dawka: \(String(format: "%.2f", dose)) mg")
                                .font(.headline)
                                .accessibilityLabel("Obliczona dawka: \(String(format: "%.2f", dose)) miligramów")
                        }
                        if let warning = result.allergyWarning {
                            AccessibleWarningText(text: warning)
                        }
                    } header: {
                        Text("Wynik")
                            .accessibleHeading()
                    }
                }

                if !history.isEmpty {
                    Section {
                        ForEach(history) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.drugName).font(.headline)
                                Text("\(String(format: "%.2f", item.calculatedDoseMg)) mg (\(String(format: "%.1f", item.dosePerKgMg)) mg/kg × \(String(format: "%.1f", item.weightKg)) kg)")
                                    .font(.caption)
                                Text(item.createdAt).font(.caption2).foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(
                                "\(item.drugName), dawka \(String(format: "%.2f", item.calculatedDoseMg)) miligramów, z dnia \(item.createdAt)"
                            )
                        }
                    } header: {
                        Text("Historia obliczeń")
                            .accessibleHeading()
                    }
                }
            }
            .navigationTitle("Kalkulator dawek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") { viewModel.activeDoseCalculatorContext = nil }
                        .accessibilityHint("Zamyka kalkulator dawek")
                }
            }
            .accessibleLoading(isLoading, label: "Obliczanie dawki")
            .task {
                if let defaultWeight = context.defaultWeightKg {
                    weight = String(format: "%.1f", defaultWeight)
                }
                await loadHistory()
            }
        }
    }

    private var canCalculate: Bool {
        !drugName.isEmpty
            && Double(dosePerKg.replacingOccurrences(of: ",", with: ".")) != nil
            && Double(weight.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func calculate() async {
        guard let dose = Double(dosePerKg.replacingOccurrences(of: ",", with: ".")),
              let weightValue = Double(weight.replacingOccurrences(of: ",", with: ".")) else { return }
        isLoading = true
        defer { isLoading = false }
        let request = DoseCalculateRequest(
            patientID: context.patientID,
            visitID: context.visitID,
            drugName: drugName,
            dosePerKgMg: dose,
            weightKg: weightValue
        )
        do {
            result = try await viewModel.calculateDose(request: request)
            await loadHistory()
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }

    private func loadHistory() async {
        do {
            history = try await viewModel.fetchDoseHistory(patientID: context.patientID)
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }
}
