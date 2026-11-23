//
//  SylantroApp.swift
//  Sylantro
//
//  Created by Wayne Mock on 11/20/26.
//

import SwiftUI
import SwiftData
import SyLibCore

/// The app (`02` §6, `00B` Task A-2): its identifiers, the logger's name, and the synced store on
/// CloudKit (`02` §5.1). When the store won't open, the window shows the recovery screen instead of
/// the library; nothing is deleted (`02` §5.3, SLT-031). Built from Score It *'s
/// `ScoreItAllApp.swift`, without its feel, celebration, TV board and scoring store.
@main
struct SylantroApp: App {
    /// The iCloud container `Sylantro.entitlements` names (SLT-011), for the store and the iCloud
    /// status.
    static let cloudKitContainerID = "iCloud.com.syzygysoftwerksllc.Sylantro"

    /// The App Store page (SLT-011), for About and the ⋯ menu's Update Available.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6837557052") ?? URL(filePath: "/")

    /// The models in the CloudKit-synced store. The configuration and the schema push both read
    /// this list, so they can't drift. A change here is a CloudKit schema change (`00B` §2).
    static let syncedModels: [any PersistentModel.Type] = SylantroSchemaV1.models

    /// The synced store, or why it didn't open.
    @State private var store: StoreState

    init() {
        AppLogger.appName = "Sylantro"
        _store = State(initialValue: StoreState.opening())
    }

    var body: some Scene {
        WindowGroup {
            switch store {
            case .open(let container):
                RootView()
                    .modelContainer(container)
            case .failed(let errorText):
                StoreRecoveryView(store: $store, errorText: errorText)
            }
        }
    }
}
