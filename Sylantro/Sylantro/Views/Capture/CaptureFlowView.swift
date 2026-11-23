import SwiftUI
import CoreGraphics
import SyLibCore

/// What a sitting of the camera is for.
enum CaptureMode: Equatable {
    /// The library's +: each Save is a new recipe, and the camera reopens for the next (SLT-045).
    case newRecipes
    /// A recipe's Add Page: the pages go to that recipe, with no page-2 question.
    case addPages(recipeID: UUID)
}

/// One sitting of the document camera, full screen (`13` §3, `14` M2-4 §6): Save asks "Is there
/// another page?" when the last page looks unfinished (SLT-046), saves through `CaptureRecorder`, then
/// pauses on `SavedPauseView` until Next Recipe or Done (SC-4, MT-30). Pages not yet saved are the pending capture; nothing in
/// it is dropped except by Cancel at "Couldn't Save".
struct CaptureFlowView: View {
    private let log = AppLogger(category: "Capture")

    let mode: CaptureMode
    let captureRecorder: CaptureRecorder

    @Environment(\.dismiss) private var dismiss

    /// This sitting's session: started when the camera first opens, reused by every recipe after.
    @State private var sessionID: UUID?
    /// Pages scanned and not yet saved, in order.
    @State private var pending: [CGImage] = []
    /// Changed to open a fresh camera.
    @State private var cameraGeneration = 0
    /// The camera was reopened by Add Page at the page-2 question: its pages join the pending ones.
    @State private var isAppending = false
    /// Save's bottom-lines read is running.
    @State private var isChecking = false
    @State private var isAskingPageTwo = false
    @State private var isShowingSaveFailed = false
    /// The page-2 flag of the save that failed, for Save at "Couldn't Save".
    @State private var failedSaveFlag = false
    /// A recipe was just saved: the pause shows in place of the camera, so nothing is scanned until
    /// Next Recipe (MT-30).
    @State private var isPaused = false

    var body: some View {
        ZStack(alignment: .top) {
            if isPaused {
                // SC-4: the pause after Save. The camera is gone while it shows, so auto-capture
                // can't take the same page again.
                SavedPauseView(onNextRecipe: nextRecipe, onDone: { dismiss() })
            } else {
                DocumentCameraView(onFinish: finished, onCancel: cancelled, onError: failed)
                    .id(cameraGeneration)
                    .ignoresSafeArea()
                    .allowsHitTesting(!isChecking)
            }

            if isChecking {
                ProgressView()
                    .controlSize(.large)
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Plain centered alerts (SLT-088).
        .alert("Is there another page?", isPresented: $isAskingPageTwo) {
            Button("Add Page") { addPage() }
            Button("Save Without It") { save(continuesOnUnscannedPage: true) }
        } message: {
            Text("This page looks like it keeps going.")
        }
        .alert("Couldn't Save", isPresented: $isShowingSaveFailed) {
            Button("Save") { retrySave() }
            Button("Cancel", role: .cancel) { dropPendingAndClose() }
        } message: {
            Text("Your pages are still here. Free up some space on this device and tap Save again.")
        }
        .task { startSessionIfNeeded() }
    }

    // MARK: The camera

    private func finished(_ pages: [CGImage]) {
        guard !pages.isEmpty else {
            cancelled()
            return
        }
        switch mode {
        case .addPages(let recipeID):
            pending = pages
            saveAddedPages(to: recipeID)
        case .newRecipes:
            pending = isAppending ? pending + pages : pages
            isAppending = false
            Task { await askAboutPageTwo() }
        }
    }

    /// Cancel with nothing pending closes the camera. With pages pending (the camera Add Page
    /// reopened), they are kept and the page-2 question is asked again (MT-12).
    private func cancelled() {
        if mode == .newRecipes && !pending.isEmpty {
            log.info(self, "camera cancelled with \(pending.count) pages pending: asking again")
            isAppending = false
            isAskingPageTwo = true
        } else {
            dismiss()
        }
    }

    /// A camera error is logged. With nothing pending it closes the camera; with pages pending they
    /// are kept and the page-2 question is asked again, as for Cancel (MT-12), so none is lost.
    private func failed(_ error: any Error) {
        log.error(self, "document camera failed: \(error)")
        cancelled()
    }

    // MARK: Is there another page?

    /// Save's one read (SLT-046): the bottom lines of the pending last page, top to bottom. A
    /// failed read counts as finished. The reason, line count and duration are logged at info; the
    /// lines themselves only at debug (`00B` §3, `14` M2-4d).
    private func askAboutPageTwo() async {
        guard let lastPage = pending.last else { return }
        isChecking = true
        let clock = ContinuousClock()
        let start = clock.now
        var reason: UnfinishedPageCheck.Reason?
        var lineCount = 0
        do {
            let reading = try await TextReader().readBottom(lastPage)
            let lines = reading.lines.sorted { $0.box.y < $1.box.y }.map(\.text)
            lineCount = lines.count
            reason = UnfinishedPageCheck.reason(lines)
            log.debug(self, "bottom lines read: \(lines)")
        } catch {
            log.error(self, "bottom-lines read failed: \(error)")
        }
        let elapsed = start.duration(to: clock.now)
        log.info(self, "bottom-lines read: \(elapsed.formatted(.units(allowed: [.milliseconds]))), \(lineCount) lines, reason: \(reason.map { "\($0)" } ?? "none")")
        isChecking = false
        if reason != nil {
            isAskingPageTwo = true
        } else {
            save(continuesOnUnscannedPage: false)
        }
    }

    /// Add Page at the page-2 question: a fresh camera whose pages join the pending ones.
    private func addPage() {
        isAppending = true
        cameraGeneration += 1
    }

    // MARK: Saving

    private func startSessionIfNeeded() {
        guard sessionID == nil else { return }
        do {
            sessionID = try captureRecorder.startSession()
        } catch {
            log.error(self, "session not started: \(error)")
        }
    }

    /// The sitting's session, started now if opening it failed earlier.
    private func currentSessionID() throws -> UUID {
        if let sessionID { return sessionID }
        let started = try captureRecorder.startSession()
        sessionID = started
        return started
    }

    /// Saves the pending pages as one new recipe, then pauses until Next Recipe or Done (MT-30).
    private func save(continuesOnUnscannedPage: Bool) {
        guard !pending.isEmpty else { return }
        do {
            let session = try currentSessionID()
            _ = try captureRecorder.saveCapture(pending, sessionID: session,
                                                continuesOnUnscannedPage: continuesOnUnscannedPage)
            pending = []
            isPaused = true
        } catch {
            log.error(self, "save failed: \(error)")
            failedSaveFlag = continuesOnUnscannedPage
            isShowingSaveFailed = true
        }
    }

    /// Add Page from a recipe: the pages go to that recipe, then the camera closes.
    private func saveAddedPages(to recipeID: UUID) {
        guard !pending.isEmpty else { return }
        do {
            let session = try currentSessionID()
            try captureRecorder.addPages(pending, to: recipeID, sessionID: session)
            pending = []
            dismiss()
        } catch {
            log.error(self, "pages not added: \(error)")
            isShowingSaveFailed = true
        }
    }

    /// Save at "Couldn't Save": the same pending pages again.
    private func retrySave() {
        switch mode {
        case .newRecipes:
            save(continuesOnUnscannedPage: failedSaveFlag)
        case .addPages(let recipeID):
            saveAddedPages(to: recipeID)
        }
    }

    /// Cancel at "Couldn't Save": the unsaved pages are dropped and the camera closes (S-19).
    private func dropPendingAndClose() {
        log.info(self, "\(pending.count) unsaved pages dropped")
        pending = []
        dismiss()
    }

    /// Next Recipe at the pause: a fresh camera in the same session.
    private func nextRecipe() {
        cameraGeneration += 1
        isPaused = false
    }
}
