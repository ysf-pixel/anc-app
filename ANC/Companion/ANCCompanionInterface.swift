import Foundation

/// Contract reserved for a future rootless Theos companion. The iOS app contains no privilege escalation,
/// socket, or jailbreak implementation; a production companion must authenticate each request and validate data.
protocol ANCCompanionTransport: Sendable {
    func status() async throws -> ANCCompanionStatus
    func send(_ request: ANCCompanionRequest) async throws -> ANCCompanionResponse
}

struct ANCCompanionStatus: Codable, Sendable { let available: Bool; let version: String? }
struct ANCCompanionRequest: Codable, Sendable { let command: String; let payload: Data? }
struct ANCCompanionResponse: Codable, Sendable { let accepted: Bool; let payload: Data? }

enum CompanionUnavailable: Error { case notInstalled }

struct DisabledCompanionTransport: ANCCompanionTransport {
    func status() async throws -> ANCCompanionStatus { .init(available: false, version: nil) }
    func send(_ request: ANCCompanionRequest) async throws -> ANCCompanionResponse { throw CompanionUnavailable.notInstalled }
}
