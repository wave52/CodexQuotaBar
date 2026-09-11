import Foundation
import Testing
@testable import CodexQuotaBar

@Test func weeklyWindowClassificationAndPace() {
    let reset = Date(timeIntervalSince1970: 7 * 24 * 60 * 60)
    let halfway = Date(timeIntervalSince1970: 3.5 * 24 * 60 * 60)
    let window = RateLimitWindow(
        usedPercent: 60,
        windowDurationMins: 10_080,
        resetsAt: Int(reset.timeIntervalSince1970)
    )

    #expect(window.isWeekly)
    #expect(abs((window.paceDelta(at: halfway) ?? 0) - 10) < 0.001)
}

@Test func percentagesAreClamped() {
    #expect(RateLimitWindow(usedPercent: -4, windowDurationMins: 300, resetsAt: nil).clampedUsedPercent == 0)
    #expect(RateLimitWindow(usedPercent: 104, windowDurationMins: 300, resetsAt: nil).clampedUsedPercent == 100)
}
