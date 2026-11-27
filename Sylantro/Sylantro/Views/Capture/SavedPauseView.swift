import SwiftUI
import SyLibUI

/// The pause after Save (`13` §3.1, SC-4, SLT-045): the recipe is saved, and nothing is scanned
/// until she taps Next Recipe, so auto-capture can't take the same page twice (`14` M2-4e, MT-30).
/// Done returns to the library. A view in the flow, not an alert or sheet.
struct SavedPauseView: View {
    /// A fresh camera, in the same session.
    let onNextRecipe: () -> Void
    /// Back to the library.
    let onDone: () -> Void

    @Environment(\.syTheme) private var syTheme

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundStyle(syTheme.primaryAccent)
            Text("Saved. Ready for the next one.")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            // The main action filled, Done a capsule below it (SLT-161).
            CapsuleButton("Next Recipe", style: .primary, fillsWidth: true) { onNextRecipe() }
            CapsuleButton("Done", fillsWidth: true) { onDone() }
        }
        .padding(24)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(syTheme.backgroundColor)
        .tint(syTheme.primaryAccent)
        // A full-screen cover doesn't take the root's cap.
        .appTextSizeCap()
    }
}

#Preview {
    SavedPauseView(onNextRecipe: {}, onDone: {})
        .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}
