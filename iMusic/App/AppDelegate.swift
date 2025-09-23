//
//  AppDelegate.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: BlurWindow!
    var settingsWindow: NSWindow?
    var settings: SettingsModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = BlurWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "iMusic"
        window.titlebarAppearsTransparent = true

        settings = SettingsModel(blurWindow: window)

        let contentView = MainView()
            .environmentObject(settings)
            .environmentObject(MusicPlayerManager.shared.libraryManager)
            .environmentObject(MusicPlayerManager.shared.playbackManager)
            .environmentObject(AppStateManager.shared)
        let hostingController = NSHostingController(rootView: contentView)
        window.contentView = hostingController.view
        window.contentView?.wantsLayer = true
        window.makeKeyAndOrderFront(nil)

        setupMenuBar()
    }

    private func setupMenuBar() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "iMusic", action: nil, keyEquivalent: "")
        let appMenu = NSMenu(title: "iMusic")
        
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        let libraryMenuItem = NSMenuItem(title: "Library", action: nil, keyEquivalent: "")
        let libraryMenu = NSMenu(title: "Library")
        
        let refreshItem = NSMenuItem(title: "Refresh Library", action: #selector(refreshLibrary), keyEquivalent: "r")
        refreshItem.target = self
        libraryMenu.addItem(refreshItem)
        
        libraryMenuItem.submenu = libraryMenu
        mainMenu.addItem(libraryMenuItem)
        
        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.center()
            settingsWindow?.title = "Settings"
            settingsWindow?.titlebarAppearsTransparent = true
            
            let settingsView = SettingsView()
                .environmentObject(settings)
            let hostingController = NSHostingController(rootView: settingsView)
            settingsWindow?.contentView = hostingController.view
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc func refreshLibrary() {
        MusicPlayerManager.shared.libraryManager.selectMusicDirectory()
        MusicPlayerManager.shared.libraryManager.refreshLibrary()
    }
}
