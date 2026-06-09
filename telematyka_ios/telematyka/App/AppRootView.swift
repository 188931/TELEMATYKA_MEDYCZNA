import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentScreen {
                case .welcome:
                    WelcomeView(viewModel: viewModel)
                case .nurseDashboard:
                    NurseDashboardView(viewModel: viewModel)
                case .patientPortal(let pesel, let fullName, let isNurse):
                    PatientPortalView(
                        viewModel: viewModel,
                        pesel: pesel,
                        fullName: fullName,
                        isNurse: isNurse
                    )
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.currentScreen.isWelcome {
                    ToolbarItem(placement: .principal) {
                        Text(viewModel.currentScreen.navigationTitle)
                            .font(.headline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .minimumScaleFactor(0.55)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 6)
                            .accessibleHeading()
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
            }
            .alert("Błąd", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
                    .accessibilityLabel("Komunikat błędu: \(viewModel.errorMessage)")
            }
            .sheet(item: $viewModel.activeLoginRole) { LoginSheet(role: $0, viewModel: viewModel) }
            .sheet(item: $viewModel.activeVisitContext) { VisitFormSheet(viewModel: viewModel, context: $0) }
            .sheet(item: $viewModel.activeRescheduleContext) { RescheduleVisitSheet(viewModel: viewModel, context: $0) }
            .sheet(item: $viewModel.activeScheduleNextContext) { ScheduleNextVisitSheet(viewModel: viewModel, context: $0) }
            .sheet(item: $viewModel.activeDoseCalculatorContext) { DoseCalculatorView(viewModel: viewModel, context: $0) }
            .sheet(item: $viewModel.activePhotoCaptureContext) { PatientPhotoCaptureView(viewModel: viewModel, context: $0) }
            .sheet(isPresented: $viewModel.activeAddPatientContext) {
                AddPatientSheet(viewModel: viewModel)
            }
        }
    }
}
