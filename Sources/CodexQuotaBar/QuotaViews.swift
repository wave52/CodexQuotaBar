import SwiftUI

struct QuotaPopoverView: View {
    @EnvironmentObject private var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let response = store.response {
                        ForEach(Array(response.snapshots.enumerated()), id: \.offset) { _, snapshot in
                            QuotaGroupView(snapshot: snapshot)
                        }
                    } else if store.isRefreshing {
                        loadingView
                    }

                    if let error = store.errorMessage {
                        errorView(error)
                    }
                }
                .padding(16)
            }

            Divider()
            footer
        }
        .frame(width: 370, height: 430)
        .task { await store.startAutomaticRefresh() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "terminal.fill")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Codex 额度")
                    .font(.headline)
                Text("每 5 分钟自动刷新")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(store.isRefreshing ? .degrees(360) : .zero)
                    .animation(store.isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: store.isRefreshing)
            }
            .buttonStyle(.borderless)
            .disabled(store.isRefreshing)
            .help("立即刷新")
        }
        .padding(16)
    }

    private var loadingView: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text("正在读取 Codex 额度…").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("暂时无法读取额度", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("重试") { store.refresh() }
        }
        .padding(12)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var footer: some View {
        HStack {
            if let date = store.lastUpdated {
                Text("更新于 \(date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("退出") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct QuotaGroupView: View {
    let snapshot: RateLimitSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(snapshot.displayName).font(.headline)
                Spacer()
                if let plan = snapshot.planType {
                    Text(plan.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(Array(snapshot.windows.enumerated()), id: \.offset) { _, window in
                WindowView(window: window)
            }
        }
        .padding(14)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WindowView: View {
    let window: RateLimitWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(window.isWeekly ? "周额度" : shortWindowTitle)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("已用 \(window.clampedUsedPercent)%")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }

            if window.isWeekly {
                SegmentedProgressView(percent: window.clampedUsedPercent)
                HStack {
                    Text(paceDescription)
                    Spacer()
                    Text("每段 ≈ 1 天预算")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                ContinuousProgressView(percent: window.clampedUsedPercent)
            }

            if let resetDate = resetDate {
                Text("\(resetDate.formatted(.relative(presentation: .named)))重置 · \(resetDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shortWindowTitle: String {
        guard let minutes = window.windowDurationMins else { return "短周期额度" }
        if minutes % 60 == 0 { return "\(minutes / 60) 小时额度" }
        return "\(minutes) 分钟额度"
    }

    private var resetDate: Date? {
        window.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    private var paceDescription: String {
        guard let delta = window.paceDelta() else { return "日均预算 14.3%" }
        let magnitude = Int(abs(delta).rounded())
        if magnitude <= 2 { return "与本周时间进度基本同步" }
        return delta > 0 ? "使用偏快 \(magnitude)%" : "使用偏慢 \(magnitude)%"
    }
}
