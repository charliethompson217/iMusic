//
//  BlurWindow.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import Cocoa

class BlurWindow: NSWindow {
    private var minBlur: Int = 0
    private var connection: UnsafeMutableRawPointer?
    private var blurFunc: ((UnsafeMutableRawPointer?, Int, Int) -> Void)?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        loadBlurSymbols()
    }

    private func loadBlurSymbols() {
        typealias CGSConnectionID = UnsafeMutableRawPointer?
        typealias CGSSetWindowBackgroundBlurRadiusFunction = @convention(c) (CGSConnectionID, Int, Int) -> Void
        typealias CGSDefaultConnectionForThreadFunction = @convention(c) () -> CGSConnectionID

        guard let dllib = dlopen(nil, RTLD_NOW) else { return }

        if let connSym = dlsym(dllib, "CGSDefaultConnectionForThread"),
           let blurSym = dlsym(dllib, "CGSSetWindowBackgroundBlurRadius") {
            let connFunc = unsafeBitCast(connSym, to: CGSDefaultConnectionForThreadFunction.self)
            connection = connFunc()
            blurFunc = unsafeBitCast(blurSym, to: CGSSetWindowBackgroundBlurRadiusFunction.self)
        }
    }

    func setBlurRadius(_ radius: Int) {
        self.isOpaque = false
        self.backgroundColor = NSColor.clear.withAlphaComponent(0.001)

        if #available(macOS 11.0, *) {
            if radius >= 1 {
                minBlur = 1
            }
        }

        guard let connection = connection, let blurFunc = blurFunc else { return }
        let effectiveRadius = max(minBlur, radius)
        blurFunc(connection, self.windowNumber, effectiveRadius)
    }
}
