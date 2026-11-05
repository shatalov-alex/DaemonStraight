//
//  main.swift
//  DaemonStraight
//
//  Explicit main entry point to ensure AppDelegate is properly initialized
//

import Cocoa

// Top-level code runs on the main thread, but the compiler has to be told
MainActor.assumeIsolated {
    // Create the application
    let app = NSApplication.shared

    // Create and set the delegate
    let delegate = AppDelegate()
    app.delegate = delegate

    // Set activation policy for menu bar app
    app.setActivationPolicy(.accessory)

    // Run the app. NSApplication holds its delegate weakly, so keep it alive until the end
    withExtendedLifetime(delegate) {
        app.run()
    }
}
