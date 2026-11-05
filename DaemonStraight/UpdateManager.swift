//
//  UpdateManager.swift
//  DaemonStraight
//
//  Update checks with Sparkle. The app is usually started right before a presentation,
//  so a check at launch never opens a window: it only reports that an update is available
//

import Cocoa
import Sparkle

class UpdateManager: NSObject, SPUStandardUserDriverDelegate {

    // MARK: - Properties
    // Called with the new version when one is found and with nil when the user has seen it
    var onAvailableVersionChanged: ((String?) -> Void)?

    private var updaterController: SPUStandardUpdaterController!

    // MARK: - Initialization
    override init() {
        super.init()
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
    }

    // MARK: - Public Methods
    func checkInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }

    // Shows the update window, including an update already found in the background
    func checkForUpdates() {
        NSApp.activate(ignoringOtherApps: true)
        updaterController.checkForUpdates(nil)
    }

    // MARK: - SPUStandardUserDriverDelegate
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        return false
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        if !state.userInitiated {
            onAvailableVersionChanged?(update.displayVersionString)
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        onAvailableVersionChanged?(nil)
    }

    func standardUserDriverWillFinishUpdateSession() {
        onAvailableVersionChanged?(nil)
    }
}
