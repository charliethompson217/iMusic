//
//  LibraryManager.swift
//  iMusic
//
//  Created by charles thompson on 9/23/25.
//

import Combine
import Foundation
import AppKit

class LibraryManager: ObservableObject {
    @Published private(set) var library: [Song] = []
    @Published private(set) var playlists: [Playlist] = []
    @Published var musicDirectoryURL: URL?
    
    private let fileManager = FileManager.default
    private let libraryFileURL: URL
    private let bookmarkKey = "musicDirectoryBookmark"
    
    struct Song: Codable, Identifiable, Hashable {
        let id: Date
        let contentHash: String
        var trackNumber: Int
        let fileURL: URL
        var title: String
        var artist: String?
        var album: String?
        var duration: Double
        var lyrics: String?
        
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
            let songID: Date
            var trackNumber: Int
        }
    }
    
    init() {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirURL = appSupportURL.appendingPathComponent("iMusic", isDirectory: true)
        libraryFileURL = appDirURL.appendingPathComponent("library.json")
        
        try? fileManager.createDirectory(at: appDirURL, withIntermediateDirectories: true)
        
        loadBookmark()
        loadLibrary()
    }
    
    private func loadBookmark() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if !isStale {
                musicDirectoryURL = url
                print("DEBUG: Loaded music dir from bookmark: \(url.path)")
            } else {
                print("DEBUG: Bookmark stale, cleared.")
                UserDefaults.standard.removeObject(forKey: bookmarkKey)
                musicDirectoryURL = nil
            }
        } catch {
            print("DEBUG: Failed to resolve bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            musicDirectoryURL = nil
        }
    }
    
    private func saveBookmark(for url: URL) {
        let success = url.startAccessingSecurityScopedResource()
        guard success else {
            print("DEBUG: Failed to start access for bookmark creation")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            print("DEBUG: Saved bookmark for \(url.path)")
        } catch {
            print("DEBUG: Failed to create bookmark: \(error)")
        }
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
            musicDirectoryURL = selectedURL
            saveBookmark(for: selectedURL)
            print("DEBUG: Selected music dir: \(selectedURL.path)")
            refreshLibrary()
        }
    }
    
    func refreshLibrary() {
        let scanner = LibraryScanner()
        
        guard let musicURL = musicDirectoryURL else {
            print("ERROR: No music directory selected.")
            return
        }
        
        guard musicURL.startAccessingSecurityScopedResource() else {
            print("ERROR: Failed to start accessing music dir: \(musicURL.path)")
            return
        }
        defer { musicURL.stopAccessingSecurityScopedResource() }
        
        if !fileManager.isReadableFile(atPath: musicURL.path) {
            print("ERROR: Cannot access music dir: \(musicURL.path)")
            return
        }
        
        let updatedLibrary = scanner.refreshLibrary(currentLibrary: library, at: musicURL)
        library = updatedLibrary.sorted { $0.id < $1.id }

        for i in 0..<library.count {
            library[i].trackNumber = i + 1
        }
        
        let activeIDs = Set(library.map { $0.id })
        for i in 0..<playlists.count {
            let beforeCount = playlists[i].songs.count
            playlists[i].songs.removeAll { !activeIDs.contains($0.songID) }
            if playlists[i].songs.count < beforeCount {
                print("DEBUG: Removed \(beforeCount - playlists[i].songs.count) stale songs from playlist '\(playlists[i].name)'")
            }
            for j in 0..<playlists[i].songs.count {
                playlists[i].songs[j].trackNumber = j + 1
            }
        }
        
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
    
    func deletePlaylist(id: UUID) {
        playlists.removeAll { $0.id == id }
        saveLibrary()
    }
    
    func addSong(_ song: Song, to playlist: Playlist) {
        guard let playlistIndex = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        let playlistSong = Playlist.PlaylistSong(songID: song.id, trackNumber: playlists[playlistIndex].songs.count + 1)
        playlists[playlistIndex].songs.append(playlistSong)
        saveLibrary()
    }
    
    func addSongs(_ songs: [Song], to playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        for song in songs {
            let ps = Playlist.PlaylistSong(songID: song.id, trackNumber: playlists[index].songs.count + 1)
            playlists[index].songs.append(ps)
        }
        saveLibrary()
    }
    
    func removeSongsFromPlaylist(_ songIDs: [Date], playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].songs.removeAll { songIDs.contains($0.songID) }
        for i in 0..<playlists[index].songs.count {
            playlists[index].songs[i].trackNumber = i + 1
        }
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
