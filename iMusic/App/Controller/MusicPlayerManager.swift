//
//  MusicPlayerManager.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import Combine
import Foundation

class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()
    
    let libraryManager: LibraryManager
    let playbackManager: PlaybackManager
    
    private init() {
        libraryManager = LibraryManager()
        playbackManager = PlaybackManager(libraryManager: libraryManager)
    }
}
