import Foundation

struct RateLimitWindow: Codable, Equatable, Sendable {
    let usedPercent: Int
    let windowDurationMins: Int?
    let resetsAt: Int?

    var clampedUsedPercent: Int { min(max(usedPercent, 0), 100) }
    var isWeekly: Bool { (windowDurationMins ?? 0) >= 8_000 }

    func paceDelta(at date: Date = .now) -> Double? {
        guard isWeekly,
              let durationMinutes = windowDurationMins,
              let resetTimestamp = resetsAt,
              durationMinutes > 0 else { return nil }

        let reset = Date(timeIntervalSince1970: TimeInterval(resetTimestamp))
        let start = reset.addingTimeInterval(-TimeInterval(durationMinutes * 60))
        let elapsed = date.timeIntervalSince(start) / TimeInterval(durationMinutes * 60)
        let elapsedPercent = min(max(elapsed, 0), 1) * 100
        return Double(clampedUsedPercent) - elapsedPercent
    }
}

struct RateLimitSnapshot: Codable, Equatable, Sendable {
    let limitId: String?
    let limitName: String?
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
    let planType: String?

    var displayName: String {
        if let limitName, !limitName.isEmpty { return limitName }
        return limitId == "codex" || limitId == nil ? "Codex" : limitId!
    }

    var windows: [RateLimitWindow] {
        [primary, secondary].compactMap { $0 }
            .sorted { ($0.windowDurationMins ?? 0) < ($1.windowDurationMins ?? 0) }
    }
}

struct RateLimitResponse: Codable, Equatable, Sendable {
    let rateLimits: RateLimitSnapshot
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?

    var snapshots: [RateLimitSnapshot] {
        let mapped = Array(rateLimitsByLimitId?.values ?? Dictionary<String, RateLimitSnapshot>().values)
        let values = mapped.isEmpty ? [rateLimits] : mapped
        return values.sorted {
            if $0.limitId == "codex" { return true }
            if $1.limitId == "codex" { return false }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    var headlineWindow: RateLimitWindow? {
        snapshots.first(where: { $0.limitId == "codex" })?.windows.first(where: \.isWeekly)
            ?? snapshots.flatMap(\.windows).first(where: \.isWeekly)
            ?? snapshots.flatMap(\.windows).first
    }
}

struct RPCEnvelope<Result: Decodable & Sendable>: Decodable, Sendable {
    let id: Int?
    let result: Result?
    let error: RPCError?
}

struct RPCError: Decodable, Error, Sendable {
    let code: Int
    let message: String
}
