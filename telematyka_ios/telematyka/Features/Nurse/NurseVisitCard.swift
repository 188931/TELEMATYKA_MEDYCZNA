import MapKit
import SwiftUI
import UIKit

struct NurseVisitCard: View {
    let visit: PatientVisit
    let now: Date
    @ObservedObject var viewModel: AppViewModel

    private let iconColumnWidth: CGFloat = 20

    private var isLocked: Bool {
        guard let visitDate = visit.parsedVisitDate else { return true }
        return now < visitDate
    }

    private var statusLabel: String {
        guard let visitDate = visit.parsedVisitDate else { return "Brak terminu" }
        if now < visitDate {
            return visit.isPastCalendarDayVisit(relativeTo: now) ? "Zaległa — czeka na godzinę" : "Oczekuje"
        }
        if visit.isPastCalendarDayVisit(relativeTo: now) { return "Zaległa — można rozpocząć" }
        return "Można rozpocząć"
    }

    private var lockIcon: String { isLocked ? "lock.fill" : "lock.open.fill" }
    private var lockColor: Color { isLocked ? AppColors.visitLocked : AppColors.visitAvailable }
    private var statusIcon: String { isLocked ? "clock" : "checkmark.circle" }
    private var lockDescription: String { isLocked ? "Zablokowana do godziny wizyty" : "Odblokowana, można rozpocząć" }

    private var cardAccessibilityLabel: String {
        "Wizyta o \(visit.displayHour), pacjent \(visit.fullName). \(lockDescription). \(statusLabel)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(visit.displayHour)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 112, alignment: .leading)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: lockIcon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(lockColor)
                            .frame(width: iconColumnWidth, alignment: .center)
                            .accessibilityHidden(true)
                        Text(visit.fullName)
                            .font(.headline)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: iconColumnWidth, alignment: .center)
                            .accessibilityHidden(true)
                        Text(statusLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Status: \(statusLabel)")
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.openReschedule(for: visit)
                } label: {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .minimumTapTarget()
                .accessibilityLabel("Zmień termin wizyty")
                .accessibilityHint("Otwiera formularz zmiany daty i godziny")

                Menu {
                    Button {
                        viewModel.openPatientDetails(for: visit, asNurse: true)
                    } label: {
                        Label("Kartoteka pacjenta", systemImage: "person.crop.circle")
                    }
                    Button {
                        viewModel.openDoseCalculator(for: visit)
                    } label: {
                        Label("Kalkulator dawek", systemImage: "pills.fill")
                    }
                    if visit.address != nil || visit.hasCoordinates {
                        Button {
                            openNavigation(for: visit)
                        } label: {
                            Label("Nawiguj do pacjenta", systemImage: "location.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .minimumTapTarget()
                .accessibilityLabel("Więcej opcji")
                .accessibilityHint("Kartoteka, kalkulator dawek i nawigacja")

                Spacer(minLength: 0)

                Button {
                    viewModel.openVisit(for: visit)
                } label: {
                    Text("Start")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .minimumTapTarget()
                .disabled(isLocked)
                .accessibilityLabel("Rozpocznij wizytę")
                .accessibilityHint(isLocked ? "Niedostępne przed godziną wizyty" : "Otwiera formularz pomiarów")
            }
            .accessibilityElement(children: .contain)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint("Użyj przycisków poniżej, aby zarządzać wizytą")
        .accessibilityAction(named: "Rozpocznij wizytę") {
            guard !isLocked else { return }
            viewModel.openVisit(for: visit)
        }
        .accessibilityAction(named: "Zmień termin") {
            viewModel.openReschedule(for: visit)
        }
    }

    private func openNavigation(for visit: PatientVisit) {
        if let lat = visit.latitude, let lng = visit.longitude {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)))
            item.name = visit.fullName
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            return
        }
        guard let address = visit.address,
              let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://maps.apple.com/?daddr=\(encoded)&dirflg=d") else { return }
        UIApplication.shared.open(url)
    }
}
