import ComposableArchitecture

/// Registers `TextService` with TCA's dependency system. The app gets the fake service;
/// tests must override it, otherwise TCA reports an unimplemented test dependency.
enum TextServiceKey: DependencyKey {
    static let liveValue: any TextService = FakeTextService()
}

extension DependencyValues {
    var textService: any TextService {
        get { self[TextServiceKey.self] }
        set { self[TextServiceKey.self] = newValue }
    }
}
