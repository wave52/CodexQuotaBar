import Foundation

enum CodexClientError: LocalizedError {
    case executableNotFound
    case serverFailed(String)
    case invalidResponse
    case rpc(String)

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "找不到 codex 命令，请先安装或更新 Codex CLI"
        case .serverFailed(let detail):
            return "Codex 服务启动失败：\(detail)"
        case .invalidResponse:
            return "Codex 返回了无法识别的额度数据"
        case .rpc(let message):
            return "读取额度失败：\(message)"
        }
    }
}

actor CodexClient {
    private let decoder = JSONDecoder()

    func fetchRateLimits() throws -> RateLimitResponse {
        guard let executable = Self.findCodexExecutable() else {
            throw CodexClientError.executableNotFound
        }

        let process = Process()
        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errors

        try process.run()

        let requests = [
            #"{"id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-quota-bar","version":"0.1.0"},"capabilities":{"experimentalApi":true}}}"#,
            #"{"method":"initialized"}"#,
            #"{"id":2,"method":"account/rateLimits/read","params":null}"#
        ].joined(separator: "\n") + "\n"

        input.fileHandleForWriting.write(Data(requests.utf8))

        var buffer = Data()
        defer {
            input.fileHandleForWriting.closeFile()
            if process.isRunning { process.terminate() }
        }

        while process.isRunning {
            let chunk = output.fileHandleForReading.availableData
            if chunk.isEmpty { break }
            buffer.append(chunk)

            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = buffer[..<newline]
                buffer.removeSubrange(...newline)
                guard !line.isEmpty,
                      let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
                      (object["id"] as? NSNumber)?.intValue == 2 else { continue }

                let envelope = try decoder.decode(RPCEnvelope<RateLimitResponse>.self, from: Data(line))
                if let error = envelope.error { throw CodexClientError.rpc(error.message) }
                guard let result = envelope.result else { throw CodexClientError.invalidResponse }
                return result
            }
        }

        let errorText = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationStatus != 0 || !errorText.isEmpty {
            throw CodexClientError.serverFailed(errorText.isEmpty ? "未知错误" : errorText)
        }
        throw CodexClientError.invalidResponse
    }

    private static func findCodexExecutable() -> String? {
        let candidates = [
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex",
            NSString(string: "~/.local/bin/codex").expandingTildeInPath
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
