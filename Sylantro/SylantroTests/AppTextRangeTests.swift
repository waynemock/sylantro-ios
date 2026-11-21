import SwiftUI
import Testing
@testable import Sylantro

/// The app's Dynamic Type range by device (`00A` §5). The system's text size up to a bound is
/// SyLib's, and tested there. From Score It *'s `AppTextRangeTests.swift`.
@Suite("The app's text range")
struct AppTextRangeTests {

    @Test("on iPad the app's range is xxxLarge to AX2")
    func iPadRange() {
        #expect(DynamicTypeSize.appRange(for: .pad) == .xxxLarge ... .accessibility2)
    }

    @Test("on iPhone, and anything else, the app's range is Large to AX2")
    func iPhoneRange() {
        #expect(DynamicTypeSize.appRange(for: .phone) == .large ... .accessibility2)
        #expect(DynamicTypeSize.appRange(for: .unspecified) == .large ... .accessibility2)
    }
}
