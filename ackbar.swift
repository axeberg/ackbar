#!/usr/bin/env swift
//
// ackbar.swift
// A lightweight macOS menu bar manager
// Requires: macOS 15+, Apple Silicon
//

import Cocoa
import os

private let logger = Logger(subsystem: "com.ackbar.app", category: "main")

// Cache arguments to avoid concurrency issues
let arguments: [String] = // Access CommandLine.arguments in a controlled way
    ProcessInfo.processInfo.arguments

// Check for CLI flags
if arguments.contains("--version") {
    let version = (try? String(contentsOfFile: "VERSION", encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)) ?? "0.1.0"
    print("ackbar v\(version)")
    exit(0)
}

if arguments.contains("--test") {
    print("ackbar compiled successfully")
    exit(0)
}

class MenuBarHider: NSObject, NSApplicationDelegate {
    var btnSeparate: NSStatusItem?
    var btnExpandCollapse: NSStatusItem?
    let statusBar = NSStatusBar.system
    @MainActor static var shared: MenuBarHider?

    private let btnHiddenLength: CGFloat = 10_000
    private let btnExpandedLength: CGFloat = NSStatusItem.variableLength
    private let prefsKey = "com.ackbar.isCollapsed"
    private let autoHideKey = "com.ackbar.autoHide"
    private let autoHideDelayKey = "com.ackbar.autoHideDelay"

    private var isCollapsed = false
    private var eventMonitor: Any?
    private var autoHideTimer: Timer?

    private var isAutoHideEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoHideKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoHideKey) }
    }

    private var autoHideDelay: TimeInterval {
        get {
            let delay = UserDefaults.standard.double(forKey: autoHideDelayKey)
            return delay > 0 ? delay : 5.0 // Default 5 seconds
        }
        set { UserDefaults.standard.set(newValue, forKey: autoHideDelayKey) }
    }

    @MainActor
    func applicationDidFinishLaunching(_: Notification) {
        MenuBarHider.shared = self

        signal(SIGINT) { _ in
            DispatchQueue.main.async {
                // Don't cleanup status items - let macOS handle them
                // This preserves their positions via autosaveName
                if let monitor = MenuBarHider.shared?.eventMonitor {
                    NSEvent.removeMonitor(monitor)
                }
                print("\n✓ Ackbar stopped")
                NSApplication.shared.terminate(nil)
            }
        }

        setupStatusItems()
        setupKeyboardShortcuts()

        // Set defaults if first run
        if UserDefaults.standard.object(forKey: autoHideKey) == nil {
            isAutoHideEnabled = true
            autoHideDelay = 5.0
        }

        // Restore previous state
        if UserDefaults.standard.bool(forKey: prefsKey) {
            collapseMenuBar()
        } else if isAutoHideEnabled {
            // Start auto-hide timer if not collapsed
            startAutoHideTimer()
        }

        logger.info("Ackbar started successfully")
        print("✓ Ackbar is running")
        print("  • Drag menu bar icons to the LEFT of the separator to hide them")
        print("  • Left-click chevron to toggle visibility")
        print("  • Right-click chevron for menu (auto-hide)")
        print("  • Press ⌘⌃M to toggle visibility")
        print("  • Press ⌘⌃⌥M for emergency reset")
        print("  • Press Ctrl+C to exit")

        // Check again without prompt to show status
        let accessEnabled = AXIsProcessTrusted()
        if !accessEnabled {
            print("\n⚠️  KEYBOARD SHORTCUTS ARE DISABLED")
            print("   Grant accessibility permissions to enable ⌘⌃M and ⌘⌃⌥M")
        }
    }

    @MainActor
    func setupStatusItems() {
        // Create expand/collapse button first (appears on the right)
        btnExpandCollapse = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        // Don't set autosaveName for chevron - prevents it from being moved
        if let button = btnExpandCollapse?.button {
            button.image = createCollapseImage()
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(toggleCollapsePressed(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Left click: toggle | Right click: menu"
        }

        // Create separator - this is what expands/collapses
        btnSeparate = statusBar.statusItem(withLength: btnExpandedLength)
        btnSeparate?.autosaveName = "com.ackbar.separator"
        if let button = btnSeparate?.button {
            button.image = createSeparatorImage()
            button.imagePosition = .imageOnly
            button.appearsDisabled = true
        }
    }

    @MainActor
    @objc func toggleCollapsePressed(sender _: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                showMenu()
            } else {
                toggleCollapse()
            }
        }
    }

    @MainActor
    @objc func toggleCollapse() {
        if isCollapsed {
            expandMenubar()
        } else {
            collapseMenuBar()
        }
    }

    @MainActor
    private func showMenu() {
        let menu = NSMenu()

        let autoHideItem = NSMenuItem(title: isAutoHideEnabled ? "Disable Auto Hide" : "Enable Auto Hide",
                                      action: #selector(toggleAutoHide), keyEquivalent: "")
        autoHideItem.target = self
        menu.addItem(autoHideItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        btnExpandCollapse?.menu = menu
        btnExpandCollapse?.button?.performClick(nil)
        btnExpandCollapse?.menu = nil
    }

    @objc func toggleAutoHide() {
        isAutoHideEnabled.toggle()
        if isAutoHideEnabled, !isCollapsed {
            startAutoHideTimer()
        }
    }

    @MainActor
    private func collapseMenuBar() {
        // Set to huge length to hide everything to the left
        btnSeparate?.length = btnHiddenLength
        isCollapsed = true
        UserDefaults.standard.set(true, forKey: prefsKey)

        if let button = btnExpandCollapse?.button {
            button.image = createExpandImage()
        }
        print("✓ Icons hidden")

        // Cancel auto-hide timer when collapsed
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    @MainActor
    private func expandMenubar() {
        // Set to variable length to show everything
        btnSeparate?.length = btnExpandedLength
        isCollapsed = false
        UserDefaults.standard.set(false, forKey: prefsKey)

        if let button = btnExpandCollapse?.button {
            button.image = createCollapseImage()
        }
        print("✓ Icons visible")

        // Start auto-hide timer if enabled
        if isAutoHideEnabled {
            startAutoHideTimer()
        }
    }

    private func startAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDelay, repeats: false) { _ in
            DispatchQueue.main.async {
                MenuBarHider.shared?.collapseMenuBar()
            }
        }
    }

    func createSeparatorImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 8, height: 18))
        image.lockFocus()

        NSColor.tertiaryLabelColor.set()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 4, y: 2))
        path.line(to: NSPoint(x: 4, y: 16))
        path.lineWidth = 1.0
        path.stroke()

        image.unlockFocus()
        return image
    }

    func createCollapseImage() -> NSImage {
        // Chevron pointing left (<<)
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()

        NSColor.labelColor.set()
        let path = NSBezierPath()

        // First chevron
        path.move(to: NSPoint(x: 7, y: 4))
        path.line(to: NSPoint(x: 3, y: 8))
        path.line(to: NSPoint(x: 7, y: 12))

        // Second chevron
        path.move(to: NSPoint(x: 13, y: 4))
        path.line(to: NSPoint(x: 9, y: 8))
        path.line(to: NSPoint(x: 13, y: 12))

        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()

        image.unlockFocus()
        return image
    }

    func createExpandImage() -> NSImage {
        // Chevron pointing right (>>)
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.lockFocus()

        NSColor.labelColor.set()
        let path = NSBezierPath()

        // First chevron
        path.move(to: NSPoint(x: 3, y: 4))
        path.line(to: NSPoint(x: 7, y: 8))
        path.line(to: NSPoint(x: 3, y: 12))

        // Second chevron
        path.move(to: NSPoint(x: 9, y: 4))
        path.line(to: NSPoint(x: 13, y: 8))
        path.line(to: NSPoint(x: 9, y: 12))

        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()

        image.unlockFocus()
        return image
    }

    func cleanup() {
        autoHideTimer?.invalidate()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let btnSeparate {
            statusBar.removeStatusItem(btnSeparate)
        }
        if let btnExpandCollapse {
            statusBar.removeStatusItem(btnExpandCollapse)
        }
    }

    private func setupKeyboardShortcuts() {
        // Check for accessibility permissions
        // Use the actual string value to avoid accessing global mutable state
        let options: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("\n⚠️  KEYBOARD SHORTCUTS DISABLED")
            print("   Ackbar needs accessibility permissions for global shortcuts.")
            print("   Please go to:")
            print("   System Settings → Privacy & Security → Accessibility")
            print("   And add Ackbar to the list")
            print("")
            return
        }

        // Use both local and global monitors for better reliability
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .control]), event.keyCode == 46 {
                let isOptionPressed = event.modifierFlags.contains(.option)
                Task { @MainActor in
                    if isOptionPressed {
                        MenuBarHider.shared?.emergencyReset()
                    } else {
                        MenuBarHider.shared?.toggleCollapse()
                    }
                }
                return nil // Consume the event
            }
            return event
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .control]), event.keyCode == 46 {
                let isOptionPressed = event.modifierFlags.contains(.option)
                Task { @MainActor in
                    if isOptionPressed {
                        MenuBarHider.shared?.emergencyReset()
                    } else {
                        MenuBarHider.shared?.toggleCollapse()
                    }
                }
            }
        }

        print("✓ Keyboard shortcuts enabled")
    }

    @MainActor
    private func emergencyReset() {
        print("🚨 Emergency reset triggered - recreating status items")

        // Remove existing items
        if let btnSeparate {
            statusBar.removeStatusItem(btnSeparate)
        }
        if let btnExpandCollapse {
            statusBar.removeStatusItem(btnExpandCollapse)
        }

        // Reset state
        isCollapsed = false
        UserDefaults.standard.set(false, forKey: prefsKey)

        // Clear saved positions
        UserDefaults.standard.removeObject(forKey: "NSStatusItem Preferred Position Item-com.ackbar.separator")
        UserDefaults.standard.removeObject(forKey: "NSStatusItem Preferred Position Item-com.ackbar.expandcollapse")
        UserDefaults.standard.synchronize()

        // Recreate status items
        setupStatusItems()

        print("✓ Emergency reset complete - status items recreated")
    }
}

// Main execution
// Use cached arguments
let args = arguments

if args.contains("--help") || args.contains("-h") {
    print("""
    ackbar - Hide menu bar icons for clean recordings

    Usage:
        ackbar        Start ackbar (Ctrl+C to exit)
        ackbar --help Show this help

    How to use:
    1. Drag menu bar icons to the LEFT of the separator to hide them
    2. Click the chevron button to toggle visibility
    3. Press ⌘⌃M to toggle visibility with keyboard
    4. Press Ctrl+C to exit and restore normal menu bar

    Keyboard Shortcuts:
        ⌘⌃M - Toggle hide/show menu bar icons
        ⌘⌃⌥M - Emergency reset (shows all icons)
    """)
    exit(0)
}

// Main execution must run on main thread
// Since we're in a script, we need to ensure we're on the main thread
if Thread.isMainThread {
    let app = NSApplication.shared
    let delegate = MenuBarHider()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
} else {
    // This shouldn't happen in normal execution
    fatalError("Script must run on main thread")
}
