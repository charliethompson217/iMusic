//
//  App.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

@main
struct App {
    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        NSApplication.shared.run()
    }
}
