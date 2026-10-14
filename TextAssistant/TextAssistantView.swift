import ComposableArchitecture
import SwiftUI

struct TextAssistantView: View {
    @Bindable var store: StoreOf<TextAssistantFeature>

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Enter text", text: $store.input)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                HStack {
                    Button("Generate") { store.send(.generateButtonTapped) }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.canGenerate)

                    Button("Cancel", role: .cancel) { store.send(.cancelButtonTapped) }
                        .buttonStyle(.bordered)
                        .disabled(!store.isLoading)
                }

                statusView

                Spacer()
            }
            .padding()
            .navigationTitle("Text Assistant")
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch store.status {
        case .idle:
            Text("Enter some text and tap Generate.")
                .foregroundStyle(.secondary)
        case .loading:
            ProgressView("Generating…")
        case .success(let result):
            Text(result)
                .textSelection(.enabled)
            ShareLink(item: result)
        case .failure(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    TextAssistantView(
        store: Store(initialState: TextAssistantFeature.State()) {
            TextAssistantFeature()
        }
    )
}
