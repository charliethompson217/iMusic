//
//  AppStateManager.swift
//  iMusic
//
//  Created by charles thompson on 9/23/25.
//

import Foundation
import Combine

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var lyricsOpen: Bool = true
    
    private init () {}

    func toggleDarkMode() {
        lyricsOpen.toggle()
    }

}
