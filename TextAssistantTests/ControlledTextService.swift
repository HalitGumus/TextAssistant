@testable import TextAssistant

/// Test double whose requests finish only when the test says so, which makes the
/// completion order deterministic without real-time waits. Like the fake service,
/// it ignores cancellation.
actor ControlledTextService: TextService {
    private var pending: [String: CheckedContinuation<String, any Error>] = [:]
    private var earlyResults: [String: Result<String, any Error>] = [:]
    private(set) var receivedTexts: [String] = []

    func generate(text: String) async throws -> String {
        receivedTexts.append(text)
        if let result = earlyResults.removeValue(forKey: text) {
            return try result.get()
        }
        return try await withCheckedThrowingContinuation { pending[text] = $0 }
    }

    /// Completes the request for `text`. If it has not reached the service yet,
    /// the result is delivered as soon as it does.
    func complete(_ text: String, with result: Result<String, any Error>) {
        if let continuation = pending.removeValue(forKey: text) {
            continuation.resume(with: result)
        } else {
            earlyResults[text] = result
        }
    }
}
