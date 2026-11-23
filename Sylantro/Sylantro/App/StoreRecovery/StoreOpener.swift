import Foundation
import SwiftData
import SyLibCore
import SyLibCloud

/// Opens the synced store on CloudKit (`02` §5.1). On failure it throws and does nothing else: it
/// never deletes, wipes or opens a fresh store in its place (SLT-031); the recovery screen decides.
enum StoreOpener {
    private static let log = AppLogger(category: "StoreRecovery")

    /// The synced store's configuration, named "Sylantro", on the private database.
    static var configuration: ModelConfiguration {
        ModelConfiguration(
            "Sylantro",
            schema: Schema(SylantroApp.syncedModels),
            cloudKitDatabase: .private(SylantroApp.cloudKitContainerID)
        )
    }

    /// Where the store's file is, for Start Fresh to set it aside.
    static var storeURL: URL { configuration.url }

    static func open() throws -> ModelContainer {
        let syncedConfig = configuration
        #if DEBUG
        if AppConfig.DebugCloudKit.runSchemaExercise {
            // CloudKit Development schema push (SLT-015): the synced models only.
            CloudKitSchema.initializeDevelopment(models: SylantroApp.syncedModels,
                                                 configuration: syncedConfig,
                                                 containerIdentifier: SylantroApp.cloudKitContainerID)
        }
        #endif
        do {
            let container = try ModelContainer(
                for: Schema(SylantroApp.syncedModels),
                migrationPlan: SylantroMigrationPlan.self,
                configurations: [syncedConfig]
            )
            log.info(StoreOpener.self, "store opened: \(syncedConfig.url.lastPathComponent)")
            return container
        } catch {
            log.error(StoreOpener.self, "store failed to open: \(error)")
            throw error
        }
    }
}
