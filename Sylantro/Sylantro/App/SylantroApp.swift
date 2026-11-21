//
//  SylantroApp.swift
//  Sylantro
//
//  Created by Wayne Mock on 11/20/26.
//

import SwiftUI
import SwiftData
import SyLibCore

/// The app (`02` §6, `00B` Task A-2): its identifiers, the logger's name, and the template store,
/// kept off CloudKit (Task A-1) until the real models replace it. Built from Score It *'s
/// `ScoreItAllApp.swift`, without its feel, celebration, TV board and scoring store.
@main
struct SylantroApp: App {
    /// The iCloud container `Sylantro.entitlements` names (SLT-011), for the iCloud status.
    static let cloudKitContainerID = "iCloud.com.syzygysoftwerksllc.Sylantro"

    /// The App Store page (SLT-011), for About and the ⋯ menu's Update Available.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6837557052") ?? URL(filePath: "/")

    init() {
        AppLogger.appName = "Sylantro"
    }

    // The template store (`00B` §3), off CloudKit (Task A-1). Its `fatalError` stays until the
    // recovery screen's task replaces it (`02` §5.3, SLT-031); no task adds another.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
