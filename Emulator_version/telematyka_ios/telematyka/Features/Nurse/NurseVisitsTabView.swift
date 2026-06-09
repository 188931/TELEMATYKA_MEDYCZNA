import SwiftUI

struct NurseVisitsTabView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var didAutoScroll = false

    var body: some View {
        if groupedVisits.isEmpty && !viewModel.isLoading {
            ContentUnavailableView("Brak wizyt", systemImage: "calendar.badge.exclamationmark")
        } else {
            ScrollViewReader { proxy in
                List {
                    ForEach(groupedVisits) { section in
                        Section(section.dayTitle) {
                            ForEach(section.visits) { visit in
                                VisitRow(visit: visit, viewModel: viewModel)
                                    .id(visitScrollID(visit))
                            }
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
        }
    }

    private var groupedVisits: [VisitDaySection] {
        VisitDaySection.build(from: viewModel.patients)
    }

    private var nextVisit: PatientVisit? {
        let now = Date()
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
            withAnimation {
                proxy.scrollTo(visitScrollID(target), anchor: .center)
            }
        }
    }

    private func visitScrollID(_ visit: PatientVisit) -> String {
        "visit-\(visit.visitID)"
    }
}

private struct VisitRow: View {
    let visit: PatientVisit
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NurseVisitCard(visit: visit, viewModel: viewModel)
            .padding(.vertical, 4)
    }
}
