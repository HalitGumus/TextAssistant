import Foundation

/// The boundary between the screen and whatever produces the text.
///
/// `@concurrent` makes the contract explicit: implementations never run on the
/// caller's actor, so service work cannot block the main thread.
protocol TextService: Sendable {
    @concurrent func generate(text: String) async throws -> String
}

enum TextServiceError: LocalizedError, Equatable {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable: "The service is currently unavailable. Please try again."
        }
    }
}
