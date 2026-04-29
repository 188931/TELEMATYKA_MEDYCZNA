import Foundation

extension AppViewModel {
    func submitMeasurements(context: VisitContext, form: VisitMeasurementForm) async {
        guard form.isValid else { return showError("Uzupełnij wymagane pola!") }
        isLoading = true
        defer { isLoading = false }

        do {
            let payload = MeasurementPayload(
                visitID: context.patient.visitID,
                bloodPressureSys: Int(form.systolic) ?? 0,
                bloodPressureDia: Int(form.diastolic) ?? 0,
                heartRate: Int(form.heartRate) ?? 0,
                glucoseLevel: Double(form.glucose) ?? 0,
                notes: form.notes
            )
            if isDebugBackendEnabled {
                try await localServer.saveMeasurements(payload)
            } else {
                try await client.requestWithoutResponse(
                    path: "/measurements/",
                    method: "POST",
                    body: payload
                )
            }
            activeVisitContext = nil
            activeScheduleNextContext = ScheduleNextContext(
                patientID: context.patient.id,
                patientName: context.patient.fullName
            )
            await refreshPatients()
        } catch {
            showError(error.localizedDescription)
        }
    }

    func scheduleNextVisit(context: ScheduleNextContext, dateString: String) async {
        guard !dateString.isEmpty else { return }
        do {
            let payload = NextVisitPayload(patientID: context.patientID, visitDate: dateString)
            if isDebugBackendEnabled {
                try await localServer.createVisit(payload)
            } else {
                try await client.requestWithoutResponse(
                    path: "/create-visit/",
                    method: "POST",
                    body: payload
                )
            }
            activeScheduleNextContext = nil
            await refreshPatients()
        } catch {
            showError(error.localizedDescription)
        }
    }

    func rescheduleVisit(context: RescheduleContext, newDate: String) async {
        guard !newDate.isEmpty else { return }
        do {
            let payload = UpdateVisitPayload(visitID: context.visitID, newDate: newDate)
            if isDebugBackendEnabled {
                try await localServer.updateVisit(payload)
            } else {
                try await client.requestWithoutResponse(
                    path: "/update-visit-date/",
                    method: "PUT",
                    body: payload
                )
            }
            activeRescheduleContext = nil
            await refreshPatients()
        } catch {
            showError(error.localizedDescription)
        }
    }
}
