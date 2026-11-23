import CoreGraphics
import Foundation
import Vision

/// Reads one page image with Vision's text recognition (`02` §4), on the device (SLT-040).
nonisolated struct TextReader: Sendable {
    /// The whole page at the accurate level.
    func read(_ image: CGImage) async throws -> PageReading {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        return try await perform(request, on: image)
    }

    /// The bottom `fraction` of the page at the accurate level: Save's quick read (SLT-046). The
    /// fast level often dropped a line's final period, so a finished step looked cut off (`14`
    /// M2-4d).
    func readBottom(_ image: CGImage, fraction: Double = 0.2) async throws -> PageReading {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        // Vision's region of interest has its origin at the lower left, so the bottom is y 0.
        request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: fraction)
        return try await perform(request, on: image)
    }

    private func perform(_ request: RecognizeTextRequest, on image: CGImage) async throws -> PageReading {
        var request = request
        request.usesLanguageCorrection = true
        // Pinned to English, so handwriting isn't read as look-alike letters (SLT-145).
        request.automaticallyDetectsLanguage = false
        request.recognitionLanguages = [Locale.Language(identifier: "en-US")]
        let observations = try await request.perform(on: image)
        let lines = observations.compactMap { observation -> PageReading.ReadLine? in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }
            // Vision's boxes have their origin at the lower left; flip to top left.
            let box = observation.boundingBox.cgRect
            return PageReading.ReadLine(
                text: candidate.string,
                confidence: Double(candidate.confidence),
                box: .init(x: box.minX, y: 1 - box.maxY, width: box.width, height: box.height)
            )
        }
        return PageReading(lines: lines)
    }
}
