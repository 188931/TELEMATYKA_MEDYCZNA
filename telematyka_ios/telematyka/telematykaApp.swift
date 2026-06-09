
import SwiftUI

@main
struct telematykaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .dynamicTypeSize(.xSmall ... .accessibility3)
                .accessibilityShowsLargeContentViewer()
        }
    }
}
