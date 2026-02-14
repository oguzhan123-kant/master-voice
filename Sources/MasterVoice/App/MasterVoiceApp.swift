import SwiftUI

@main
struct MasterVoiceApp: App {
    @StateObject private var viewModel = MasterVoiceViewModel()

    var body: some Scene {
        WindowGroup("Master Voice") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 620, minHeight: 460)
                .task {
                    await viewModel.startup()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
