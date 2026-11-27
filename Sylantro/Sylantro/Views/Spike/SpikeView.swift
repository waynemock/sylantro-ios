import SwiftUI
import SyLibUI
import UniformTypeIdentifiers

/// The hidden accuracy-spike screen (`11` M1-3, SLT-093): add captures, run them through the
/// reader and the structurer, and export the results. Saves nothing. Shown when SLT-093's `AppConfig.AccuracySpike.isEnabled` is on; reached
/// from Settings as a sheet that closes only from Done, after a confirmation (`11` M1-7).
struct SpikeView: View {
    /// What the one file importer is picking. Two importers on one view don't both present.
    private enum ImportMode {
        case photos
        case testSetFolder
    }

    @State private var runner = SpikeRunner()
    @State private var isImporting = false
    @State private var importMode = ImportMode.photos
    @State private var isExporting = false
    @State private var isConfirmingClose = false
    /// The task Run All (or BG Run All) started, kept so Close can cancel it.
    @State private var runTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase

    /// The spike's hold on `ScreenAwake`, so Auto-Lock doesn't pause a run (`11` M1-10).
    private static let screenAwakeHolder = "accuracySpike"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                // Wraps on a narrow screen (`11` M1-11).
                FlowLayout {
                    // The remembered test folder in one tap; the folder picker only when there
                    // is none (SLT-154).
                    CapsuleButton("Load Test Set") {
                        if !runner.loadSavedTestSet() {
                            importMode = .testSetFolder
                            isImporting = true
                        }
                    }
                    .disabled(runner.isRunning)
                    CapsuleButton("Run All", style: .accent) {
                        runTask = Task { await runner.runAll() }
                    }
                    .disabled(runner.isRunning || runner.captures.isEmpty)
                    // Spike only (`15` M3-3l, M3-3o): Run All inside a continued-processing task,
                    // to see whether the model answers in the background. Close cancels it as
                    // Run All.
                    CapsuleButton("BG Run All") {
                        runTask = Task { await runner.runAllInBackground() }
                    }
                    .disabled(runner.isRunning || runner.captures.isEmpty)
                    // Works mid-run and after failures (M1-9).
                    CapsuleButton("Export Results") {
                        isExporting = true
                    }
                    .disabled(runner.report == nil)
                }
            }
            // How many captures are done or failed (`11` M1-13).
            if !runner.captures.isEmpty {
                Section {
                    ProgressView(value: Double(runner.processedCount), total: Double(runner.captures.count))
                    Text("\(runner.processedCount) / \(runner.captures.count)")
                        .monospacedDigit()
                }
            }
            if !RecipeStructurer.isAvailable {
                Section {
                    Text("Apple Intelligence isn't available on this device. Pages will be read but not structured.")
                }
            }
            if runner.captures.isEmpty {
                Text("Tap Load Test Set to load the test pages.")
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
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    isConfirmingClose = true
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                // SyLib's `MoreMenu`, as the library's (SLT-161).
                MoreMenu(look: .toolbar, accessibilityLabel: "More") {
                    Button("Add Capture") {
                        importMode = .photos
                        isImporting = true
                    }
                    Button("Clear") {
                        runner.clear()
                    }
                    // Enabled whenever there is a capture or a report to clear.
                    .disabled(runner.captures.isEmpty && runner.report == nil)
                }
            }
        }
        // Closes only from Done, after the confirmation.
        .interactiveDismissDisabled()
        // A plain centered alert, never one anchored to a button (SLT-088).
        .alert("Close the accuracy spike?", isPresented: $isConfirmingClose) {
            Button("Close", role: .destructive) {
                runTask?.cancel()
                ScreenAwake.shared.update(awake: false, holder: Self.screenAwakeHolder)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Captures and results that weren't exported are cleared. A run in progress stops.")
        }
        // Structuring runs only while Sylantro is in front (SLT-144).
        .onChange(of: scenePhase, initial: true) { _, phase in
            // The screen stays awake while the sheet is open and in front.
            ScreenAwake.shared.update(awake: phase == .active, holder: Self.screenAwakeHolder)
            if phase == .active {
                runner.sceneBecameActive()
            } else {
                runner.sceneLeftActive()
            }
        }
        .onDisappear {
            ScreenAwake.shared.update(awake: false, holder: Self.screenAwakeHolder)
        }
        .fileImporter(isPresented: $isImporting,
                      allowedContentTypes: importMode == .photos ? [.image] : [.folder],
                      allowsMultipleSelection: importMode == .photos) { result in
            guard case .success(let urls) = result, !urls.isEmpty else {
                return
            }
            switch importMode {
            case .photos: runner.addCapture(urls)
            case .testSetFolder: runner.loadTestSet(folder: urls[0])
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
