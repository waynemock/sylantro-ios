import Foundation

/// Switched features (`02` §1), checked before every archive (`00B` §6). Plain constants, the same
/// in every build configuration. From Score It *'s `Utilities/AppConfig.swift`.
enum AppConfig {
    /// The CloudKit Development schema push (SLT-015): SyLibCloud's
    /// `CloudKitSchema.initializeDevelopment`, run once on a device signed into iCloud before a
    /// Production deploy. Nothing reads it until the synced store exists. **Must be `false` in any
    /// archive** (`00B` §6).
    enum DebugCloudKit {
        static let runSchemaExercise = false
    }
}
