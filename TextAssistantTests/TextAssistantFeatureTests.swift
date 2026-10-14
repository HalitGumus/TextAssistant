import ComposableArchitecture
import Testing
@testable import TextAssistant

@MainActor
struct TextAssistantFeatureTests {
    private let service = ControlledTextService()
    private let store: TestStoreOf<TextAssistantFeature>

    init() {
        store = TestStore(initialState: TextAssistantFeature.State()) {
            TextAssistantFeature()
        } withDependencies: { [service] in
            $0.textService = service
        }
    }

    // (a) Required: the current result survives an older request finishing later.
    @Test func olderSuccessDoesNotOverrideNewerResult() async {
        await startRequest("slow first", id: 1)
        await startRequest("second", id: 2)

        await service.complete("second", with: .success("Result: second"))
        await store.receive(\.generateResponse) {
            $0.activeRequestID = nil
            $0.status = .success("Result: second")
        }

        // The older request finishes last. Its effect was cancelled, so nothing is
        // delivered; and even if its response reached the reducer, state is unchanged.
        await service.complete("slow first", with: .success("Result: slow first"))
        await store.send(.generateResponse(id: 1, .success("Result: slow first")))
    }

    // (b) Required: a cancelled request's result never shows up.
    @Test func lateResultIsNotShownAfterCancel() async {
        await startRequest("slow first", id: 1)

        await store.send(.cancelButtonTapped) {
            $0.activeRequestID = nil
            $0.status = .idle
        }

        await service.complete("slow first", with: .success("Result: slow first"))
        await store.send(.generateResponse(id: 1, .success("Result: slow first")))
        #expect(store.state.input == "slow first")
    }

    @Test func olderErrorDoesNotOverrideNewerResult() async {
        await startRequest("slow error", id: 1)
        await startRequest("second", id: 2)

        await service.complete("second", with: .success("Result: second"))
        await store.receive(\.generateResponse) {
            $0.activeRequestID = nil
            $0.status = .success("Result: second")
        }

        await service.complete("slow error", with: .failure(TextServiceError.unavailable))
        await store.send(.generateResponse(id: 1, .failure(TextServiceError.unavailable)))
    }

    @Test func blankInputDoesNotAffectOngoingRequest() async {
        await startRequest("first", id: 1)

        await store.send(\.binding.input, "   ") { $0.input = "   " }
        await store.send(.generateButtonTapped)

        await service.complete("first", with: .success("Result: first"))
        await store.receive(\.generateResponse) {
            $0.activeRequestID = nil
            $0.status = .success("Result: first")
        }
        #expect(await service.receivedTexts == ["first"])
    }

    private func startRequest(_ text: String, id: Int) async {
        await store.send(\.binding.input, text) { $0.input = text }
        await store.send(.generateButtonTapped) {
            $0.lastRequestID = id
            $0.activeRequestID = id
            $0.status = .loading
        }
    }
}
