//
//  PlaybackManager.swift
//  iMusic
//
//  Created by charles thompson on 9/23/25.
//

import Combine
import Foundation
import AVFoundation
import AppKit

class PlaybackManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var currentSong: LibraryManager.Song?
    @Published private(set) var currentLyrics: String?
    @Published private(set) var currentAlbumArt: NSImage?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentFilePath: String?
    @Published private(set) var isShuffleEnabled: Bool = false
    
    private var player: AVAudioPlayer?
    private let libraryManager: LibraryManager
    private var shuffledLibrary: [LibraryManager.Song]?
    
    init(libraryManager: LibraryManager) {
        self.libraryManager = libraryManager
        super.init()
    }
    
    func toggleShuffle() {
        isShuffleEnabled.toggle()
        
        if isShuffleEnabled {
            if let library = libraryManager.library as? [LibraryManager.Song] {
                var rng = SystemRandomNumberGenerator()
                shuffledLibrary = library.shuffled(using: &rng)
            }
        } else {
            shuffledLibrary = nil
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            nextSong()
        }
    }
    
    func playPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func playSong(_ song: LibraryManager.Song) {
        guard let dirURL = libraryManager.musicDirectoryURL else {
            print("DEBUG: No music directory URL available for security-scoped access")
            return
        }
        
        let success = dirURL.startAccessingSecurityScopedResource()
        if !success {
            print("DEBUG: Failed to start security-scoped access for directory: \(dirURL.path)")
        }
        defer {
            if success {
                dirURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: song.fileURL)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            currentSong = song
            currentLyrics = song.lyrics
            currentFilePath = song.fileURL.path
            isPlaying = true
            
            let asset = AVURLAsset(url: song.fileURL)
            let metadata = asset.metadata
            if let artworkItem = metadata.first(where: { $0.commonKey == .commonKeyArtwork }),
               let data = artworkItem.dataValue,
               let image = NSImage(data: data) {
                currentAlbumArt = image
            } else {
                currentAlbumArt = nil
            }
        } catch {
            print("Error playing song: \(error)")
        }
    }
    
    func nextSong() {
        guard let current = currentSong else { return }
        
        if isShuffleEnabled, let shuffled = shuffledLibrary {
            if let currentIndex = shuffled.firstIndex(where: { $0.id == current.id }),
               currentIndex + 1 < shuffled.count {
                playSong(shuffled[currentIndex + 1])
            } else if !shuffled.isEmpty {
                playSong(shuffled[0])
            }
        } else if let library = libraryManager.library as? [LibraryManager.Song],
                  let currentIndex = library.firstIndex(where: { $0.id == current.id }),
                  currentIndex + 1 < library.count {
            playSong(library[currentIndex + 1])
        }
    }
    
    func previousSong() {
        guard let current = currentSong else { return }
        
        if isShuffleEnabled, let shuffled = shuffledLibrary {
            if let currentIndex = shuffled.firstIndex(where: { $0.id == current.id }),
               currentIndex > 0 {
                playSong(shuffled[currentIndex - 1])
            }
        } else if let library = libraryManager.library as? [LibraryManager.Song],
                  let currentIndex = library.firstIndex(where: { $0.id == current.id }),
                  currentIndex > 0 {
            playSong(library[currentIndex - 1])
        }
    }
    
    func getCurrentPlaybackTime() -> Double {
        guard let player = player else { return 0.0 }
        return player.currentTime
    }
    
    func setPlaybackTime(_ time: Double) {
        guard let player = player, time >= 0, time <= player.duration else { return }
        player.currentTime = time
    }
}
