import SwiftUI
import SyLibUI

/// The detail column when no recipe is selected. From Score It *'s `NoGameSelectedView.swift`.
struct NoRecipeSelectedView: View {
    @Environment(\.syTheme) private var syTheme

    var body: some View {
        Text("Choose a recipe")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(syTheme.backgroundColor)
    }
}

#Preview {
    NoRecipeSelectedView()
        .environment(\.syTheme, SyTheme(type: .forest, colorScheme: .light))
}
