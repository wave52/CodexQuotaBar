import Combine
import Foundation

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var response: RateLimitResponse?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let client = CodexClient()
    private var refreshTask: Task<Void, Never>?

    var menuBarPercent: Int? {
        response?.headlineWindow.map { 100 - $0.clampedUsedPercent }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        refreshTask = Task {
            do {
                response = try await client.fetchRateLimits()
                lastUpdated = .now
            } catch {
                errorMessage = error.localizedDescription
            }
            isRefreshing = false
        }
    }

    func startAutomaticRefresh() async {
        refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(300))
            refresh()
        }
    }
}
