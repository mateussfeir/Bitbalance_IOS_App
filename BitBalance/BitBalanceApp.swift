import SwiftUI


@main
struct BitBalanceApp: App {
    @StateObject private var assetStore = AssetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(assetStore)
                .task {
                    await assetStore.refreshPrices(trigger: "app launch")
                }
        }
    }
}
