import Foundation
import Testing
@testable import CodexQuotaBar

@Test func weeklyWindowClassificationAndTimeProgress() {
    let reset = Date(timeIntervalSince1970: 7 * 24 * 60 * 60)
    let halfway = Date(timeIntervalSince1970: 3.5 * 24 * 60 * 60)
    let window = RateLimitWindow(
        usedPercent: 60,
        windowDurationMins: 10_080,
        resetsAt: Int(reset.timeIntervalSince1970)
    )

    #expect(window.isWeekly)
    #expect(window.elapsedTimePercent(at: halfway) == 50)
}

@Test func timeProgressUsesExactResetTime() throws {
    let formatter = ISO8601DateFormatter()
    let reset = try #require(formatter.date(from: "2026-09-27T07:01:00+08:00"))
    let now = try #require(formatter.date(from: "2026-09-23T20:48:00+08:00"))
    let window = RateLimitWindow(usedPercent: 49, windowDurationMins: 10_080,
                                 resetsAt: Int(reset.timeIntervalSince1970))
    let percent = try #require(window.elapsedTimePercent(at: now))

    #expect(abs(percent - 51.0615079365) < 0.0000001)
    let nextSecond = try #require(window.elapsedTimePercent(at: now.addingTimeInterval(1)))
    #expect(abs(nextSecond - percent - 100.0 / 604_800) < 0.0000001)
}

@Test func timeProgressClampsToActualWindow() {
    let window = RateLimitWindow(usedPercent: 90, windowDurationMins: 300, resetsAt: 18_000)
    let cases: [(TimeInterval, Double)] = [(-60, 0), (0, 0), (9_000, 50), (18_000, 100), (18_060, 100)]
    for (elapsedSeconds, expected) in cases {
        #expect(window.elapsedTimePercent(at: Date(timeIntervalSince1970: elapsedSeconds)) == expected)
    }
}

@Test func timeProgressRequiresValidTimingData() {
    for duration in [nil, 0, -1] as [Int?] {
        let window = RateLimitWindow(usedPercent: 49, windowDurationMins: duration, resetsAt: 18_000)
        #expect(window.elapsedTimePercent() == nil)
    }
    #expect(RateLimitWindow(usedPercent: 49, windowDurationMins: 10_080, resetsAt: nil)
        .elapsedTimePercent() == nil)
}

@Test func percentagesAreClamped() {
    #expect(RateLimitWindow(usedPercent: -4, windowDurationMins: 300, resetsAt: nil).clampedUsedPercent == 0)
    #expect(RateLimitWindow(usedPercent: 104, windowDurationMins: 300, resetsAt: nil).clampedUsedPercent == 100)
}
