import Testing
@testable import TextAssistant

struct FakeTextServiceTests {
    private let service = FakeTextService(normalDelay: .zero, slowDelay: .zero)

    @Test(arguments: ["  hello \n", "Slow hello"])
    func returnsTrimmedResult(text: String) async throws {
        let expected = "Result: " + text.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(try await service.generate(text: text) == expected)
    }

    @Test(arguments: ["error", "ERROR now", "  Slow Error later"])
    func errorPrefixesThrowUnavailable(text: String) async {
        await #expect(throws: TextServiceError.unavailable) {
            try await service.generate(text: text)
        }
    }

    @Test func ignoresCancellation() async throws {
        let task = Task { [service] in try await service.generate(text: "hello") }
        task.cancel()
        #expect(try await task.value == "Result: hello")
    }
}
