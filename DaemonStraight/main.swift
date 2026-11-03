//
//  main.swift
//  DaemonStraight
//
//  Explicit main entry point to ensure AppDelegate is properly initialized
//

import Cocoa
@MainActor

// Create the application
let app = NSApplication.shared

// Create and set the delegate
let delegate = AppDelegate()
app.delegate = delegate

// Set activation policy for menu bar app
app.setActivationPolicy(.accessory)

// Run the app on the main actor
app.run()
