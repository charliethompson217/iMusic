//
//  LibraryManager.swift
//  iMusic
//
//  Created by charles thompson on 9/23/25.
//

import Combine
import Foundation
import AVFoundation
import CryptoKit
import AppKit

class LibraryManager: ObservableObject {
    @Published private(set) var library: [Song] = []
    @Published private(set) var playlists: [Playlist] = []
    @Published var musicDirectoryURL: URL?
    
    private let fileManager = FileManager.default
    private let libraryFileURL: URL
    private var bookmarkData: Data?
    
    struct Song: Codable, Identifiable, Hashable {
        let id: String
        var trackNumber: Int
        let fileURL: URL
        let title: String
        let artist: String?
        let album: String?
        let duration: Double
        let lyrics: String?
        
        static func ==(lhs: Song, rhs: Song) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    struct Playlist: Codable, Identifiable {
        let id: UUID
        let name: String
        var songs: [PlaylistSong]
        
        struct PlaylistSong: Codable {
            let songID: String
            var trackNumber: Int
        }
    }
    
    init() {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirURL = appSupportURL.appendingPathComponent("MusicPlayerApp", isDirectory: true)
        libraryFileURL = appDirURL.appendingPathComponent("library.json")
        
        try? fileManager.createDirectory(at: appDirURL, withIntermediateDirectories: true)
        
        loadLibrary()
        loadMusicDirectoryBookmark()
    }
    
    func selectMusicDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Music Library Folder"
        openPanel.message = "Choose the folder containing your MP3 files (e.g., ~/Music or ~/songs)."
        openPanel.prompt = "Select"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.directoryURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Music")
        
        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            if let bookmark = try? selectedURL.bookmarkData(options: .withSecurityScope) {
                bookmarkData = bookmark
                musicDirectoryURL = selectedURL
                saveMusicDirectoryBookmark()
                print("DEBUG: Bookmarked music dir: \(selectedURL.path)")
                refreshLibrary()
            } else {
                print("ERROR: Failed to create bookmark for \(selectedURL.path)")
            }
        }
    }
    
    private func loadMusicDirectoryBookmark() {
        let bookmarkURL = libraryFileURL.deletingLastPathComponent().appendingPathComponent("musicBookmark.data")
        guard let data = try? Data(contentsOf: bookmarkURL) else { return }
        
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return }
        
        if isStale {
            print("DEBUG: Bookmark is stale, consider re-selecting directory")
            bookmarkData = nil
            musicDirectoryURL = nil
            return
        }
        
        musicDirectoryURL = url
        bookmarkData = data
        print("DEBUG: Loaded bookmarked music dir: \(url.path)")
    }
    
    private func saveMusicDirectoryBookmark() {
        let bookmarkURL = libraryFileURL.deletingLastPathComponent().appendingPathComponent("musicBookmark.data")
        try? bookmarkData?.write(to: bookmarkURL)
    }
    
    func refreshLibrary() {
        guard let musicURL = musicDirectoryURL else {
            print("DEBUG: No music directory selected. Call selectMusicDirectory() first.")
            let fallbackURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("songs")
            if !fileManager.fileExists(atPath: fallbackURL.path) {
                print("DEBUG: Fallback ~/songs doesn't exist.")
                return
            }
            scanDirectory(at: fallbackURL)
            return
        }
        
        let success = musicURL.startAccessingSecurityScopedResource()
        defer { if success { musicURL.stopAccessingSecurityScopedResource() } }
        
        if !success {
            print("ERROR: Failed to access bookmarked music dir: \(musicURL.path)")
            return
        }
        
        scanDirectory(at: musicURL)
    }
    
    private func scanDirectory(at directoryURL: URL) {
        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey]) else {
            print("DEBUG: Enumerator failed for \(directoryURL.path)")
            return
        }
        
        print("DEBUG: Starting recursive scan of \(directoryURL.path)")
        
        let ignoreFileURL = directoryURL.appendingPathComponent(".ignore")
        var ignorePatterns: [String] = []
        if let ignoreContent = try? String(contentsOf: ignoreFileURL) {
            ignorePatterns = ignoreContent.split(separator: "\n").compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : String($0) }
            print("DEBUG: Loaded \(ignorePatterns.count) ignore patterns: \(ignorePatterns)")
        } else {
            print("DEBUG: No .ignore file found or unreadable.")
        }
        
        var newSongs: [Song] = []
        var seenIDs: Set<String> = Set(library.map { $0.id })
        var currentTrack = library.count + 1
        var fileCount = 0
        var skippedCount = 0
        
        for case let fileURL as URL in enumerator {
            fileCount += 1
            print("DEBUG: Enumerating: \(fileURL.path)")
            
            guard fileURL.pathExtension.lowercased() == "mp3" else {
                print("DEBUG: Skipping non-MP3: \(fileURL.path)")
                skippedCount += 1
                continue
            }
            
            if let matchingPattern = ignorePatterns.first(where: { fileURL.path.contains($0) }) {
                print("DEBUG: Skipping due to ignore pattern '\(matchingPattern)': \(fileURL.path)")
                skippedCount += 1
                continue
            }
            
            guard let attributes = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  attributes.isRegularFile == true else {
                print("DEBUG: Skipping non-regular file (e.g., dir): \(fileURL.path)")
                skippedCount += 1
                continue
            }
            
            print("DEBUG: Processing new MP3: \(fileURL.path)")
            
            guard let data = try? Data(contentsOf: fileURL) else {
                print("DEBUG: Failed to read file data for hash: \(fileURL.path)")
                skippedCount += 1
                continue
            }
            let id = SHA256.hash(data: data).compactMap({ String(format: "%02x", $0) }).joined()
            
            if seenIDs.contains(id) {
                print("DEBUG: Skipping duplicate song by ID: \(id) for \(fileURL.path)")
                skippedCount += 1
                continue
            }
            seenIDs.insert(id)
            
            let asset = AVURLAsset(url: fileURL)
            let metadata = asset.metadata
            let title = metadata.filter({ $0.commonKey == .commonKeyTitle }).first?.stringValue ?? fileURL.lastPathComponent
            let artist = metadata.filter({ $0.commonKey == .commonKeyArtist }).first?.stringValue
            let album = metadata.filter({ $0.commonKey == .commonKeyAlbumName }).first?.stringValue
            let lyrics = metadata.first(where: { item in
                if let key = item.key as? AVMetadataKey {
                    if item.keySpace == AVMetadataKeySpace.id3 && key == AVMetadataKey.id3MetadataKeyUnsynchronizedLyric {
                        return true
                    } else if item.keySpace == AVMetadataKeySpace.iTunes && key == AVMetadataKey.iTunesMetadataKeyLyrics {
                        return true
                    }
                }
                return false
            })?.stringValue
            let duration = asset.duration.seconds
            
            let song = Song(id: id, trackNumber: currentTrack, fileURL: fileURL, title: title, artist: artist, album: album, duration: duration, lyrics: lyrics)
            newSongs.append(song)
            currentTrack += 1
            print("DEBUG: Added song '\(title)' by \(artist ?? "Unknown") with ID \(id)")
        }
        
        print("DEBUG: Scan complete. Processed \(fileCount) items, skipped \(skippedCount), added \(newSongs.count) new songs.")
        
        library.append(contentsOf: newSongs)
        library.sort { $0.trackNumber < $1.trackNumber }
        saveLibrary()
    }
    
    func removeSong(_ song: Song) {
        guard let index = library.firstIndex(where: { $0.id == song.id }) else { return }
        library.remove(at: index)
        
        for i in index..<library.count {
            library[i].trackNumber -= 1
        }
        
        for i in 0..<playlists.count {
            playlists[i].songs.removeAll { $0.songID == song.id }
            for j in 0..<playlists[i].songs.count {
                playlists[i].songs[j].trackNumber = j + 1
            }
        }
        
        saveLibrary()
    }
    
    func createPlaylist(name: String) {
        let playlist = Playlist(id: UUID(), name: name, songs: [])
        playlists.append(playlist)
        saveLibrary()
    }
    
    func addSong(_ song: Song, to playlist: Playlist) {
        guard let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        let playlistSong = Playlist.PlaylistSong(songID: song.id, trackNumber: playlists[playlistIndex].songs.count + 1)
        playlists[playlistIndex].songs.append(playlistSong)
        saveLibrary()
    }
    
    func reorderPlaylist(_ playlist: Playlist, from: Int, to: Int) {
        guard let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }),
              from >= 0, from < playlists[playlistIndex].songs.count,
              to >= 0, to < playlists[playlistIndex].songs.count else { return }
        
        let song = playlists[playlistIndex].songs.remove(at: from)
        playlists[playlistIndex].songs.insert(song, at: to)
        
        for i in 0..<playlists[playlistIndex].songs.count {
            playlists[playlistIndex].songs[i].trackNumber = i + 1
        }
        
        saveLibrary()
    }
    
    private func saveLibrary() {
        let data = LibraryData(library: library, playlists: playlists)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: libraryFileURL)
        } catch {
            print("Error saving library: \(error)")
        }
    }
    
    private func loadLibrary() {
        do {
            let jsonData = try Data(contentsOf: libraryFileURL)
            let decoder = JSONDecoder()
            let data = try decoder.decode(LibraryData.self, from: jsonData)
            library = data.library
            playlists = data.playlists
        } catch {
            print("Error loading library: \(error)")
        }
    }
    
    private struct LibraryData: Codable {
        let library: [Song]
        let playlists: [Playlist]
    }
}
