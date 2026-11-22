#if DEBUG
import SwiftUI
import UniformTypeIdentifiers

/// The hidden accuracy-spike screen (`11` M1-3, SLT-093): add captures, run them through the
/// reader and the structurer, and export the results. Saves nothing. Debug builds only; reached
/// from Settings.
struct SpikeView: View {
    @State private var runner = SpikeRunner()
    @State private var isImporting = false
    @State private var isExporting = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            if !RecipeStructurer.isAvailable {
                Section {
                    Text("Apple Intelligence isn't available on this device. Pages will be read but not structured.")
                }
            }
            if runner.captures.isEmpty {
                Text("Add a capture: pick the photos of one recipe's pages.")
            } else {
                ForEach(runner.captures) { capture in
                    VStack(alignment: .leading) {
                        Text(capture.urls.map(\.lastPathComponent).joined(separator: " + "))
                        Text(Self.statusText(capture.status))
                        if capture.status == .done, let result = capture.result {
                            Text(Self.detailText(result))
                        }
                    }
                }
            }
        }
        .navigationTitle("Accuracy Spike")
        .toolbar {
            Button("Add Capture") {
                isImporting = true
            }
            Button("Run All") {
                Task { await runner.runAll() }
            }
            .disabled(runner.isRunning || runner.captures.isEmpty)
            Button("Export Results") {
                isExporting = true
            }
            .disabled(runner.report == nil)
            Button("Clear") {
                runner.clear()
            }
        }
        // Structuring runs only while Sylantro is in front (SLT-144).
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                runner.sceneBecameActive()
            } else {
                runner.sceneLeftActive()
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.image], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result, !urls.isEmpty {
                runner.addCapture(urls)
            }
        }
        .fileExporter(isPresented: $isExporting,
                      document: runner.report.map(SpikeReportDocument.init),
                      contentType: .json,
                      defaultFilename: runner.report.map { Self.fileName($0) }) { _ in }
    }

    private static func statusText(_ status: SpikeRunner.Status) -> String {
        switch status {
        case .waiting: "Waiting"
        case .reading: "Reading…"
        case .structuring: "Structuring…"
        case .waitingForApp: "Waiting for Sylantro to be open"
        case .done: "Done"
        case .failed(let error): "Failed: " + error
        }
    }

    /// `<n> recipe(s) · read <r> ms · structure <s> ms`; `r` is the total of the pages' reads, and
    /// the structure part is left out when the capture wasn't structured.
    private static func detailText(_ result: SpikeCaptureResult) -> String {
        var text = "\(result.recipes.count) recipe(s) · read \(result.readMillis.reduce(0, +)) ms"
        if let structureMillis = result.structureMillis {
            text += " · structure \(structureMillis) ms"
        }
        return text
    }

    /// `spike-results-<yyyy-MM-dd-HHmm>`, from the run's time; the exporter adds `.json`.
    private static func fileName(_ report: SpikeReport) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "spike-results-" + formatter.string(from: report.runAt)
    }
}

/// The report as a JSON file for `fileExporter`. Export only.
private struct SpikeReportDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let report: SpikeReport

    init(_ report: SpikeReport) {
        self.report = report
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try report.encoded())
    }
}
#endif
