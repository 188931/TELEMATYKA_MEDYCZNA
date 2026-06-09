import Foundation

extension AppViewModel {
    func refreshPatients() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if isDebugBackendEnabled {
                await localServer.syncPending(to: client)
                patients = await localServer.patientsWithVisits()
                nursePatients = await localServer.allPatients().map {
                    NursePatient(id: $0.id, fullName: $0.fullName, pesel: $0.pesel)
                }
            } else {
                patients = try await client.request(path: "/patients-with-visits/")
                nursePatients = try await client.request(path: "/patients/")
            }
        } catch {
            showError(error.localizedDescription)
        }
    }

    func openVisit(for patient: PatientVisit) {
        activeVisitContext = VisitContext(patient: patient)
    }

    func openReschedule(for patient: PatientVisit) {
        activeRescheduleContext = RescheduleContext(
            visitID: patient.visitID,
            currentDate: patient.visitDate
        )
    }

    func openPatientDetails(for patient: PatientVisit, asNurse: Bool) {
        nurseReturnTab = nurseSelectedTab
        currentScreen = .patientPortal(
            pesel: patient.pesel ?? "",
            fullName: patient.fullName,
            isNurse: asNurse
        )
    }

    func openPatientDetails(for patient: NursePatient, asNurse: Bool) {
        nurseReturnTab = 1
        currentScreen = .patientPortal(
            pesel: patient.pesel,
            fullName: patient.fullName,
            isNurse: asNurse
        )
    }

}
