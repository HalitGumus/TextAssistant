import ComposableArchitecture
import Foundation

@Reducer
struct TextAssistantFeature {
    @ObservableState
    struct State: Equatable {
        var input = ""
        var status: Status = .idle
        /// The only request whose response may change `status`; `nil` when nothing is in flight.
        var activeRequestID: Int?
        var lastRequestID = 0

        var canGenerate: Bool { !trimmedInput.isEmpty }
        var isLoading: Bool { status == .loading }

        fileprivate var trimmedInput: String {
            input.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    enum Status: Equatable {
        case idle
        case loading
        case success(String)
        case failure(message: String)
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case generateButtonTapped
        case cancelButtonTapped
        case generateResponse(id: Int, Result<String, any Error>)
    }

    private enum CancelID { case generate }

    @Dependency(\.textService) var textService

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .generateButtonTapped:
                // Blank input is ignored and leaves any request in flight untouched.
                let text = state.trimmedInput
                guard !text.isEmpty else { return .none }

                state.lastRequestID += 1
                let id = state.lastRequestID
                state.activeRequestID = id
                state.status = .loading

                // Cancel the previous request synchronously, here in the reducer, instead of
                // with `cancelInFlight`: that runs when the new effect's task starts, so two
                // effects started back to back can race and the older one can cancel the newer.
                // Cancellation is best-effort; `activeRequestID` is what guarantees correctness.
                return .concatenate(
                    .cancel(id: CancelID.generate),
                    .run { [textService] send in
                        let result: Result<String, any Error>
                        do {
                            result = .success(try await textService.generate(text: text))
                        } catch {
                            result = .failure(error)
                        }
                        await send(.generateResponse(id: id, result))
                    }
                    .cancellable(id: CancelID.generate)
                )

            case .cancelButtonTapped:
                guard state.activeRequestID != nil else { return .none }
                state.activeRequestID = nil
                state.status = .idle
                return .cancel(id: CancelID.generate)

            case let .generateResponse(id, result):
                // Responses from replaced or cancelled requests are dropped here.
                guard id == state.activeRequestID else { return .none }
                state.activeRequestID = nil

                switch result {
                case let .success(text):
                    state.status = .success(text)
                case let .failure(error):
                    state.status = .failure(message: Self.message(for: error))
                }
                return .none
            }
        }
    }

    private static func message(for error: any Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
