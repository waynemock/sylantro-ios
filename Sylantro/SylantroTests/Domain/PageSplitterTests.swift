import Foundation
import Testing
@testable import Sylantro

/// `PageSplitter` (`11` M1-4, SLT-140): a capture's lines in sections by heading. Every line is
/// made up.
@Suite("Page splitter")
struct PageSplitterTests {
    @Test("headings split the sections")
    func headingsSplitTheSections() {
        let split = PageSplitter.split([["Test Soup", "Serves 2", "Ingredients", "1 cup water", "Directions:", "Boil it.", "Notes", "Good cold."]])
        #expect(split.header == ["Test Soup", "Serves 2"])
        #expect(split.ingredients == ["1 cup water"])
        #expect(split.steps == ["Boil it."])
        #expect(split.notes == ["Good cold."])
        #expect(split.hasIngredientsAndSteps)
    }

    @Test("a section runs onto the next page")
    func sectionRunsOntoNextPage() {
        let split = PageSplitter.split([["Ingredients", "1 cup water"], ["2 cups flour", "Method", "Mix."]])
        #expect(split.ingredients == ["1 cup water", "2 cups flour"])
        #expect(split.steps == ["Mix."])
    }

    @Test("no headings leaves everything in the header")
    func noHeadingsLeavesHeader() {
        let lines = ["Test Soup", "1 cup water", "Boil it."]
        let split = PageSplitter.split([lines])
        #expect(split.header == lines)
        #expect(split.ingredients.isEmpty)
        #expect(split.steps.isEmpty)
        #expect(split.notes.isEmpty)
        #expect(split.equipment.isEmpty)
        #expect(split.nutrition.isEmpty)
        #expect(!split.hasIngredientsAndSteps)
    }

    @Test("bullets are removed and equipment and nutrition are found")
    func bulletsEquipmentAndNutrition() {
        let split = PageSplitter.split([["Equipment", "• Pot", "Nutrition Facts", "100 calories"]])
        #expect(split.equipment == ["Pot"])
        #expect(split.nutrition == ["100 calories"])
    }
}
