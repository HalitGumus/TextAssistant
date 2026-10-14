# Text Assistant

## Run & test
Open `TextAssistant.xcodeproj`, choose an iOS 17+ simulator, then ⌘R to run or ⌘U to test. On first build, **Trust & Enable** the TCA macros.

```bash
xcodebuild test -project TextAssistant.xcodeproj -scheme TextAssistant -skipMacroValidation \
  -destination 'platform=iOS Simulator,name=<iOS 17+ simulator>'
```

## Environment
- Xcode 26.2, Swift 6 language mode, iOS 17.0 minimum, The Composable Architecture 1.26
- Default Actor Isolation: **nonisolated**. TCA's macros conflict with MainActor-by-default, and reducers are pure value types; `Store` and views are main-actor-isolated by TCA and SwiftUI.

## Time spent
~3 hours

## Operation lifecycle
The reducer starts the request as an effect that the `Store`, not the view, owns and runs. The app keeps one store for the screen's lifetime. If a parent feature presented this screen (`@Presents`/`ifLet`), dismissing it would cancel its effects automatically.

## Late results
Every response carries its request ID, and the reducer applies it only if it matches `activeRequestID`, so responses from replaced or cancelled requests never change state.

## Technical choice
I cancel the previous effect synchronously in the reducer instead of using `cancellable(id:cancelInFlight:)`. For `.run` effects, `cancelInFlight` fires when the new effect's task starts, so two quick requests can race and the older one cancels the newer, leaving the screen stuck loading. A stress test reproduced this in 18 of 60 runs.

## Known limitations
- Cancelling an effect that hasn't started yet is a no-op; the request-ID check still drops its response.
- No UI tests.

## Exposing the service to Flutter
- **Contract:** defined with Pigeon, so request, result and error types are generated and type-checked in both Dart and Swift. Calls arrive on the platform main thread; native runs the service off-main and replies on main.
- **Request ID:** Dart creates it (monotonic int) and sends it with every `generate` call; every native reply carries it back. Dart keeps the active ID and ignores replies for any other ID, the same rule as the iOS reducer, so correctness doesn't depend on platform ordering.
- **Cancellation:** `cancel(requestId)` is fire-and-forget. Dart moves to idle immediately without waiting for native. Native cancels its task (best effort) and never delivers a result or error for a cancelled ID. Disposing the screen or engine cancels all active IDs.
- **Errors:** stable codes instead of message matching: `FlutterError(code: "unavailable" | "invalid_input" | "internal", message: <user-facing text>, details: {requestId, retryable})`. Cancellation is a status, not an error, so Dart never shows it.

## AI usage
I used Claude Code to scaffold the Xcode project, port the screen to TCA, draft this README and review concurrency edge cases. I verified its output by reading every line, running the tests on iOS 17.5 and 26.2, temporarily removing the request-ID check and the cancellation to confirm the tests fail, and stress-running the four verification flows against the real fake service, which is how the `cancelInFlight` race was found.
