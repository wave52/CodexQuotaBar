import SwiftUI

@main
struct CodexQuotaBarApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            QuotaPopoverView()
                .environmentObject(store)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "terminal.fill")
                if let remaining = store.menuBarPercent {
                    Text("\(remaining)%")
                }
            }
            .task {
                if store.response == nil { store.refresh() }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
