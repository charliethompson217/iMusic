//
//  LibraryScanner.swift
//  iMusic
//
//  Created by charles thompson on 9/26/25.
//

import Foundation
import AVFoundation
import CryptoKit

class LibraryScanner {
    private let fileManager = FileManager.default
    
    func refreshLibrary(currentLibrary: [LibraryManager.Song], at directoryURL: URL) -> [LibraryManager.Song] {
        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isRegularFileKey]) else {
            print("DEBUG: Enumerator failed for \(directoryURL.path)")
            return []
        }
        
        print("DEBUG: Starting recursive refresh scan of \(directoryURL.path)")
        
        let ignoreFileURL = directoryURL.appendingPathComponent(".ignore")
        var ignorePatterns: [String] = []
        if let ignoreContent = try? String(contentsOf: ignoreFileURL) {
            ignorePatterns = ignoreContent.split(separator: "\n").compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : String($0) }
            print("DEBUG: Loaded \(ignorePatterns.count) ignore patterns: \(ignorePatterns)")
        } else {
            print("DEBUG: No .ignore file found or unreadable.")
        }
        
        let existingByPath: [String: LibraryManager.Song] = currentLibrary.reduce(into: [:]) { $0[$1.fileURL.path] = $1 }
        let existingByHash: [String: LibraryManager.Song] = currentLibrary.reduce(into: [:]) { $0[$1.contentHash] = $1 }
        print("DEBUG: currentLibrary count: \(currentLibrary.count)")
        print("DEBUG: existingByPath count: \(existingByPath.count)")
        print("DEBUG: existingByHash count: \(existingByHash.count)")
        
        var newSongs: [LibraryManager.Song] = []
        var hashToPath: [String: String] = [:]
        var fileCount = 0
        var skippedBecauseReadFailed = 0
        var skippedBecauseHashDuplicate = 0
        var reusedByPath = 0
        var reusedByHash = 0
        var added = 0
        
        for case let fileURL as URL in enumerator {
            
            guard let attributes = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  attributes.isRegularFile == true else {
                continue
            }
            
            if ignorePatterns.first(where: { fileURL.path.contains($0) }) != nil {
                continue
            }
            
            guard fileURL.pathExtension.lowercased() == "mp3" else {
                continue
            }
            
            fileCount += 1
                        
            guard let data = try? Data(contentsOf: fileURL) else {
                print("DEBUG: Failed to read file data for hash: \(fileURL.path)")
                skippedBecauseReadFailed += 1
                continue
            }
            
            let contentHash = SHA256.hash(data: data).compactMap({ String(format: "%02x", $0) }).joined()
            
            let path = fileURL.path
            if let existingPath = hashToPath[contentHash], existingPath != path {
                print("DEBUG: Skipping duplicate content hash \(contentHash) for \(path), claimed by \(existingPath)")
                skippedBecauseHashDuplicate += 1
                continue
            }
            hashToPath[contentHash] = path
            
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
            
            let song: LibraryManager.Song
            if let existing = existingByPath[path] {
                song = LibraryManager.Song(
                    id: existing.id,
                    contentHash: contentHash,
                    trackNumber: 0, // gets set by the manager
                    fileURL: fileURL,
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    lyrics: lyrics
                )
                reusedByPath += 1
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                print("DEBUG: Reusing by path '\(title)' by \(artist ?? "Unknown") at \(path) (ID: \(formatter.string(from: existing.id)))")
            } else if let existing = existingByHash[contentHash] {
                song = LibraryManager.Song(
                    id: existing.id,
                    contentHash: contentHash,
                    trackNumber: 0, // gets set by the manager
                    fileURL: fileURL,
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    lyrics: lyrics
                )
                reusedByHash += 1
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                print("DEBUG: Reusing by hash '\(title)' by \(artist ?? "Unknown") at \(path) from \(existing.fileURL.path) (ID: \(formatter.string(from: existing.id)))")
            } else {
                let now = Date()
                song = LibraryManager.Song(
                    id: now,
                    contentHash: contentHash,
                    trackNumber: 0, // gets set by the manager
                    fileURL: fileURL,
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    lyrics: lyrics
                )
                added += 1
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                print("DEBUG: Adding new song '\(title)' by \(artist ?? "Unknown") at \(path) with ID \(formatter.string(from: now))")
            }
            
            newSongs.append(song)
        }
        
        print("DEBUG: Refresh complete. Processed \(fileCount) items, skipped \(skippedBecauseReadFailed) because of read failure, skipped \(skippedBecauseHashDuplicate) because of hash duplicate, reused \(reusedByPath) by path, reused \(reusedByHash) by hash, added \(added) resulting in \(newSongs.count) songs.")
        
        return newSongs
    }
}
