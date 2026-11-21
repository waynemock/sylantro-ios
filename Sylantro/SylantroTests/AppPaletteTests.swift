import SwiftUI
import Testing
import SyLibUI
@testable import Sylantro

/// The App Color (SLT-085): the stored palette, Forest when nothing is stored. From Score It *'s
/// `AppPaletteTests.swift`.
@Suite("The App Color")
struct AppPaletteTests {
    @Test("a stored palette's id gives that palette")
    func storedIDGivesItsPalette() {
        for type in SyTheme.ThemeType.allCases {
            #expect(AppPalette.theme(type.rawValue, colorScheme: .dark) == SyTheme(type: type, colorScheme: .dark))
            #expect(AppPalette.theme(type.rawValue, colorScheme: .light) == SyTheme(type: type, colorScheme: .light))
        }
    }

    @Test("an empty or unknown id gives Forest")
    func emptyOrUnknownIsForest() {
        #expect(AppPalette.defaultType == .forest)
        #expect(AppPalette.theme("", colorScheme: .dark) == SyTheme(type: .forest, colorScheme: .dark))
        #expect(AppPalette.theme("NotAPalette", colorScheme: .light) == SyTheme(type: .forest, colorScheme: .light))
    }
}
