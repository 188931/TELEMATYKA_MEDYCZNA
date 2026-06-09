import SwiftUI

struct AddPatientSheet: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var pesel = ""
    @State private var address = ""
    @State private var allergies = ""
    @State private var chronicDiseases = ""
    @State private var password = ""
    @State private var scheduleVisit = true
    @State private var visitDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Imię *", text: $firstName)
                        .accessibleFormLabel("Imię", required: true)
                    TextField("Nazwisko *", text: $lastName)
                        .accessibleFormLabel("Nazwisko", required: true)
                    TextField("PESEL *", text: $pesel).keyboardType(.numberPad)
                        .accessibleFormLabel("PESEL, jedenaście cyfr", required: true)
                    TextField("Adres", text: $address)
                        .accessibleFormLabel("Adres")
                    TextField("Alergie", text: $allergies, prompt: Text("Wpisz alergie, jeśli występują"))
                        .accessibleFormLabel("Alergie")
                    TextField("Choroby przewlekłe", text: $chronicDiseases, prompt: Text("Wpisz choroby, jeśli występują"))
                        .accessibleFormLabel("Choroby przewlekłe")
                } header: {
                    Text("Dane pacjenta")
                        .accessibleHeading()
                }

                Section {
                    SecureField("Hasło logowania *", text: $password)
                        .accessibleFormLabel("Hasło logowania", required: true)
                        .textContentType(.newPassword)
                } header: {
                    Text("Konto pacjenta")
                        .accessibleHeading()
                }

                Section {
                    Toggle("Zaplanuj pierwszą wizytę", isOn: $scheduleVisit)
                        .accessibilityHint("Włącza wybór terminu pierwszej wizyty")
                    if scheduleVisit {
                        DatePicker(
                            "Termin wizyty",
                            selection: $visitDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accessibilityHint("Data i godzina pierwszej wizyty")
                    }
                } header: {
                    Text("Wizyta")
                        .accessibleHeading()
                }

                if !isValid {
                    AccessibleWarningText(text: validationMessage)
                        .font(.caption)
                }

                Text(AccessibleTheme.requiredHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(AccessibleTheme.requiredHint)
            }
            .navigationTitle("Nowy pacjent")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { viewModel.activeAddPatientContext = false }
                        .accessibilityHint("Zamyka formularz bez zapisywania")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dodaj") {
                        Task { await submit() }
                    }
                    .disabled(!isValid)
                    .accessibilityHint(isValid ? "Zapisuje nowego pacjenta" : validationMessage)
                }
            }
        }
    }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && pesel.count == 11 && !password.isEmpty
    }

    private var validationMessage: String {
        if firstName.isEmpty { return "Uzupełnij imię pacjenta" }
        if lastName.isEmpty { return "Uzupełnij nazwisko pacjenta" }
        if pesel.count != 11 { return "PESEL musi mieć jedenaście cyfr" }
        if password.isEmpty { return "Uzupełnij hasło logowania" }
        return ""
    }

    private func submit() async {
        let payload = CreatePatientPayload(
            firstName: firstName,
            lastName: lastName,
            pesel: pesel,
            address: address,
            allergies: allergies,
            chronicDiseases: chronicDiseases,
            password: password,
            visitDate: scheduleVisit ? VisitDateFormatter.string(from: visitDate) : nil
        )
        await viewModel.createPatient(payload: payload)
    }
}
