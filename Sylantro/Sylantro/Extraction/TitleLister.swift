import Foundation
import FoundationModels

/// The model's list of a page's recipe titles (`15` RV-35, M3-5s). Spike only.
@Generable
nonisolated struct GeneratedPageTitles {
    @Guide(description: "The title of every separate recipe on this page, exactly as printed, in reading order. One title if there is one recipe.")
    var titles: [String]
}

/// Asks the model, once, for every recipe title on a capture's lines (RV-35), with the
/// structurer's numbered lines and instructions, greedy and capped as the header part is. A title
/// is kept only when it is a whole line, or two adjacent lines, of the page, compared normalized
/// (as SLT-151 checks); the rest are dropped and counted. Not used outside the spike; the
/// structurer, its prompts and `promptVersion` are unchanged.
nonisolated enum TitleLister {
    /// The kept titles, in the model's order, and how many it gave that weren't on the page.
    static func titles(numberedLines lines: [String]) async throws -> (titles: [String], dropped: Int) {
        let session = LanguageModelSession(instructions: RecipeStructurer.instructions)
        let options = GenerationOptions(samplingMode: .greedy, maximumResponseTokens: RecipeStructurer.TokenCap.header)
        let answer = try await session.respond(to: RecipeStructurer.numbered(lines), generating: GeneratedPageTitles.self,
                                               options: options).content
        return kept(answer.titles, lines: lines)
    }

    /// The answers that are a whole line or two adjacent lines of `lines`, normalized; the count of
    /// the rest. Empty answers ("none") are dropped too.
    static func kept(_ answers: [String], lines: [String]) -> (titles: [String], dropped: Int) {
        let normalized = lines.map(TextMatch.normalize)
        var candidates = Set(normalized)
        for index in normalized.indices.dropLast() {
            candidates.insert(TextMatch.normalize(lines[index] + " " + lines[index + 1]))
        }
        var kept: [String] = []
        var dropped = 0
        for answer in answers {
            let text = TextMatch.normalize(answer)
            if !TextMatch.isEmptyAnswer(answer), !text.isEmpty, candidates.contains(text) {
                kept.append(answer)
            } else {
                dropped += 1
            }
        }
        return (kept, dropped)
    }
}
