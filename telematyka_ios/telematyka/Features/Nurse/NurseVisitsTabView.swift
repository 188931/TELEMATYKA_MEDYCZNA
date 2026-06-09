import Combine
import SwiftUI

struct NurseVisitsTabView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var didAutoScroll = false
    @State private var now = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        if groupedVisits.isEmpty && !viewModel.isLoading {
            ContentUnavailableView("Brak wizyt", systemImage: "calendar.badge.exclamationmark")
                .accessibilityLabel("Brak zaplanowanych wizyt")
        } else {
            ScrollViewReader { proxy in
                List {
                    ForEach(groupedVisits) { section in
                        Section {
                            ForEach(section.visits) { visit in
                                VisitRow(visit: visit, now: now, viewModel: viewModel)
                                    .id(visitScrollID(visit))
                            }
                        } header: {
                            Text(section.dayTitle)
                                .accessibleHeading()
                        }
                    }
                }
                .onAppear {
                    autoScrollIfNeeded(proxy: proxy)
                }
                .onChange(of: viewModel.patients.count) { _, _ in
                    didAutoScroll = false
                    autoScrollIfNeeded(proxy: proxy)
                }
            }
            .listStyle(.insetGrouped)
            .onReceive(minuteTimer) { date in
                now = date
            }
            .accessibilityLabel("Lista wizyt pielęgniarki")
        }
    }

    private var groupedVisits: [VisitDaySection] {
        VisitDaySection.build(from: viewModel.patients)
    }

    private var nextVisit: PatientVisit? {
        return viewModel.patients
            .filter { ($0.parsedVisitDate ?? .distantFuture) >= now }
            .sorted { ($0.parsedVisitDate ?? .distantFuture) < ($1.parsedVisitDate ?? .distantFuture) }
            .first
    }

    private func autoScrollIfNeeded(proxy: ScrollViewProxy) {
        guard !didAutoScroll else { return }
        guard let target = nextVisit ?? viewModel.patients.first else { return }
        didAutoScroll = true
        DispatchQueue.main.async {
            AccessibleAnimation.scroll(
                proxy: proxy,
                to: visitScrollID(target),
                reduceMotion: reduceMotion
            )
        }
    }

    private func visitScrollID(_ visit: PatientVisit) -> String {
        "visit-\(visit.visitID)"
    }
}

private struct VisitRow: View {
    let visit: PatientVisit
    let now: Date
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NurseVisitCard(visit: visit, now: now, viewModel: viewModel)
            .padding(.vertical, 4)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
