import ComposableArchitecture
import SwiftUI

@main
struct TextAssistantApp: App {
    static let store = Store(initialState: TextAssistantFeature.State()) {
        TextAssistantFeature()
    }

    var body: some Scene {
        WindowGroup {
            TextAssistantView(store: Self.store)
        }
    }
}
