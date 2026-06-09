import SwiftUI

struct PatientPortalView: View {
    @ObservedObject var viewModel: AppViewModel
    let pesel: String
    let fullName: String
    let isNurse: Bool

    @State private var history: [PatientHistoryRecord] = []
    @State private var doseHistory: [DoseHistoryRecord] = []
    @State private var patientID: Int?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                portalHeader
                patientInfoCard
                if let patientID {
                    PatientPhotoGalleryView(
                        viewModel: viewModel,
                        patientID: patientID,
                        canAddPhoto: isNurse,
                        visitID: nil
                    )
                }
                if isNurse {
                    doseHistorySection
                }
                historySection
            }
            .padding()
        }
        .accessibleLoading(isLoading, label: "Ładowanie kartoteki pacjenta")
        .task(id: pesel) { await loadHistory() }
    }
}

private extension PatientPortalView {
    var portalHeader: some View {
        HStack {
            Button {
                isNurse ? viewModel.returnToNurseDashboard() : viewModel.logout()
            } label: {
                Label(
                    isNurse ? viewModel.nurseBackButtonTitle : "Wyloguj",
                    systemImage: isNurse ? "arrow.left" : "rectangle.portrait.and.arrow.right"
                )
            }
            .buttonStyle(.bordered)
            .minimumTapTarget()
            .accessibilityHint(isNurse ? "Wraca do panelu pielęgniarki" : "Kończy sesję i wraca do ekranu startowego")
            Spacer()
        }
    }

    var patientInfoCard: some View {
        let profile = history.first
        let allergiesText = profile?.allergies ?? "Brak"
        let cardLabel = """
        Dane pacjenta. Pacjent \(fullName). PESEL \(pesel). \
        Adres \(profile?.address ?? "Brak danych"). \
        Alergie \(allergiesText). \
        Choroby przewlekłe \(profile?.chronicDiseases ?? "Brak"). \
        Ciśnienie \(profile.map { "\($0.bloodPressureSys) na \($0.bloodPressureDia) milimetrów słupa rtęci" } ?? "brak danych"). \
        Tętno \(profile.map { "\($0.heartRate) uderzeń na minutę" } ?? "brak danych"). \
        Temperatura \(profile?.temperatureC.map { String(format: "%.1f stopni Celsjusza", $0) } ?? "brak danych"). \
        Waga \(profile?.weightKg.map { String(format: "%.1f kilogramów", $0) } ?? "brak danych"). \
        Saturacja \(profile?.spo2Percent.map { "\($0) procent" } ?? "brak danych"). \
        Glikemia \(profile.map { "\($0.glucoseLevel) miligramów na decylitr" } ?? "brak danych").
        """

        return VStack(alignment: .leading, spacing: 8) {
            Text("Dane pacjenta")
                .font(.title3)
                .bold()
                .accessibleHeading()
            Divider()
            Text("Pacjent: \(fullName)")
            Text("PESEL: \(pesel)")
            Text("Adres: \(profile?.address ?? "Brak danych")")
            if allergiesText == "Brak" || allergiesText.isEmpty {
                Text("Alergie: Brak")
            } else {
                AccessibleWarningText(text: "Alergie: \(allergiesText)")
            }
            Text("Choroby przewlekłe: \(profile?.chronicDiseases ?? "Brak")")
            Divider()
            Text("Aktualny stan")
                .font(.headline)
                .accessibleHeading()
            Text("Ciśnienie: \(profile.map { "\($0.bloodPressureSys)/\($0.bloodPressureDia) mmHg" } ?? "-")")
            Text("Tętno: \(profile.map { "\($0.heartRate) bpm" } ?? "-")")
            Text("Temperatura: \(profile?.temperatureC.map { String(format: "%.1f °C", $0) } ?? "-")")
            Text("Waga: \(profile?.weightKg.map { String(format: "%.1f kg", $0) } ?? "-")")
            Text("SpO2: \(profile?.spo2Percent.map { "\($0)%" } ?? "-")")
            Text("Glikemia: \(profile.map { "\($0.glucoseLevel) mg/dL" } ?? "-")")
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardLabel)
    }

    var doseHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Obliczenia dawek")
                    .font(.title3)
                    .bold()
                    .accessibleHeading()
                Spacer()
                if let patientID {
                    Button("Kalkulator") {
                        viewModel.openDoseCalculator(
                            patientID: patientID,
                            patientName: fullName,
                            allergies: history.first?.allergies
                        )
                    }
                    .buttonStyle(.bordered)
                    .minimumTapTarget()
                    .accessibilityHint("Otwiera kalkulator dawek leków")
                }
            }
            ForEach(doseHistory) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.drugName).font(.headline)
                    Text("\(String(format: "%.2f", item.calculatedDoseMg)) mg")
                    if let warning = item.allergyWarning {
                        AccessibleWarningText(text: warning)
                            .font(.caption)
                    }
                    Text(item.createdAt).font(.caption2).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(doseItemLabel(item))
            }
            if doseHistory.isEmpty && !isLoading {
                Text("Brak obliczeń dawek")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Brak historii obliczeń dawek")
            }
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Historia pomiarów")
                .font(.title3)
                .bold()
                .accessibleHeading()
            ForEach(history) { HistoryCard(item: $0) }
            if history.isEmpty && !isLoading {
                ContentUnavailableView("Brak historii", systemImage: "doc.text.magnifyingglass")
                    .accessibilityLabel("Brak historii pomiarów")
            }
        }
    }

    func doseItemLabel(_ item: DoseHistoryRecord) -> String {
        var parts = ["Lek \(item.drugName)", "dawka \(String(format: "%.2f", item.calculatedDoseMg)) miligramów"]
        if let warning = item.allergyWarning { parts.append(warning) }
        parts.append("data \(item.createdAt)")
        return parts.joined(separator: ". ")
    }

    func loadHistory() async {
        guard !pesel.isEmpty else { history = []; return }
        isLoading = true
        defer { isLoading = false }
        do {
            history = try await viewModel.fetchPatientHistory(pesel: pesel)
            if let historyPatientID = history.first?.patientID {
                patientID = historyPatientID
            } else if let profile = try? await viewModel.fetchPatientProfile(pesel: pesel) {
                patientID = profile.id
            }
            if let patientID, isNurse {
                doseHistory = try await viewModel.fetchDoseHistory(patientID: patientID)
            }
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }
}

private struct HistoryCard: View {
    let item: PatientHistoryRecord

    private var cardLabel: String {
        var parts = [
            "Wizyta \(item.visitDate)",
            "ciśnienie \(item.bloodPressureSys) na \(item.bloodPressureDia)",
            "tętno \(item.heartRate)",
            "cukier \(item.glucoseLevel) miligramów na decylitr",
            "notatki \(item.notes.isEmpty ? "brak" : item.notes)"
        ]
        if let temp = item.temperatureC { parts.append("temperatura \(String(format: "%.1f", temp)) stopni") }
        if let weight = item.weightKg { parts.append("waga \(String(format: "%.1f", weight)) kilogramów") }
        if let spo2 = item.spo2Percent { parts.append("saturacja \(spo2) procent") }
        return parts.joined(separator: ". ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.visitDate).font(.headline)
            Text("Ciśnienie: \(item.bloodPressureSys)/\(item.bloodPressureDia) mmHg")
            Text("Tętno: \(item.heartRate) bpm")
            if let temp = item.temperatureC { Text("Temperatura: \(String(format: "%.1f", temp)) °C") }
            if let weight = item.weightKg { Text("Waga: \(String(format: "%.1f", weight)) kg") }
            if let spo2 = item.spo2Percent { Text("SpO2: \(spo2)%") }
            Text("Cukier: \(item.glucoseLevel) mg/dL")
            Text("Notatki: \(item.notes.isEmpty ? "-" : item.notes)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardLabel)
    }
}
