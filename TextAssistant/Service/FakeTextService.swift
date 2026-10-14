import Foundation

/// Simulates a third-party SDK that does not support cancellation.
///
/// - Input is trimmed; prefixes are matched case-insensitively.
/// - `slow…` waits ~2 s, everything else ~300 ms.
/// - `error…` / `slow error…` throw `TextServiceError.unavailable` after the delay.
/// - Cancelling the calling task has no effect: the delay always completes and the
///   normal result or error is delivered.
struct FakeTextService: TextService {
    var normalDelay: Duration = .milliseconds(300)
    var slowDelay: Duration = .seconds(2)

    @concurrent
    func generate(text: String) async throws -> String {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = input.lowercased()

        let isSlow = lowercased.hasPrefix("slow")
        let isError = lowercased.hasPrefix("error") || lowercased.hasPrefix("slow error")

        await waitIgnoringCancellation(for: isSlow ? slowDelay : normalDelay)

        if isError {
            throw TextServiceError.unavailable
        }
        return "Result: \(input)"
    }

    /// `Task.sleep` throws as soon as the caller is cancelled. An unstructured task does
    /// not inherit the caller's cancellation, so sleeping inside one keeps the full delay.
    private func waitIgnoringCancellation(for duration: Duration) async {
        await Task { try? await Task.sleep(for: duration) }.value
    }
}
