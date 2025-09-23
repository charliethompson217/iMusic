//
//  SongTableView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI
import AppKit
@_spi(Advanced) import SwiftUIIntrospect

typealias Song = LibraryManager.Song

extension ComparisonResult {
    var reversed: ComparisonResult {
        switch self {
        case .orderedAscending: return .orderedDescending
        case .orderedSame: return .orderedSame
        case .orderedDescending: return .orderedAscending
        }
    }
}

struct UnknownStringComparator: SortComparator {
    typealias Compared = String?
    let unknown: String
    var order: SortOrder = .forward
    
    func compare(_ lhs: String?, _ rhs: String?) -> ComparisonResult {
        let left = lhs ?? unknown
        let right = rhs ?? unknown
        
        let result: ComparisonResult
        if left < right {
            result = .orderedAscending
        } else if left > right {
            result = .orderedDescending
        } else {
            result = .orderedSame
        }
        
        return order == .forward ? result : result.reversed
    }
}

struct TrackNumberCell: View {
    let song: Song
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text("\(song.trackNumber)")
            .font(settings.font(for: settings.songTable.trackNumber.family, size: settings.songTable.trackNumber.size))
            .foregroundColor(settings.songTable.trackNumber.color)
    }
}

struct TitleCell: View {
    let song: Song
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(song.title)
            .font(settings.font(for: settings.songTable.title.family, size: settings.songTable.title.size))
            .foregroundColor(settings.songTable.title.color)
    }
}

struct ArtistCell: View {
    let song: Song
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(song.artist ?? "Unknown Artist")
            .font(settings.font(for: settings.songTable.artist.family, size: settings.songTable.artist.size))
            .foregroundColor(settings.songTable.artist.color)
    }
}

struct AlbumCell: View {
    let song: Song
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(song.album ?? "Unknown Album")
            .font(settings.font(for: settings.songTable.album.family, size: settings.songTable.album.size))
            .foregroundColor(settings.songTable.album.color)
    }
}

struct DurationCell: View {
    let song: Song
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(formatDuration(song.duration))
            .font(settings.font(for: settings.songTable.duration.family, size: settings.songTable.duration.size))
            .foregroundColor(settings.songTable.duration.color)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct SongTableView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager
    @State private var selectedSongID: Song.ID?
    @State private var sortOrder: [KeyPathComparator<Song>] = [KeyPathComparator(\.title)]
    
    var sortedSongs: [Song] {
        libraryManager.library.sorted(using: sortOrder)
    }
    
    private var trackNumberColumn: some TableColumnContent<Song, KeyPathComparator<Song>> {
        TableColumn("#", value: \.trackNumber) { song in
            TrackNumberCell(song: song)
        }
        .width(min: 40, ideal: 50, max: 60)
    }
    
    private var titleColumn: some TableColumnContent<Song, KeyPathComparator<Song>> {
        TableColumn("Title", value: \.title) { song in
            TitleCell(song: song)
        }
    }
    
    private var artistColumn: some TableColumnContent<Song, KeyPathComparator<Song>> {
        TableColumn("Artist", value: \.artist, comparator: UnknownStringComparator(unknown: "Unknown Artist")) { song in
            ArtistCell(song: song)
        }
    }
    
    private var albumColumn: some TableColumnContent<Song, KeyPathComparator<Song>> {
        TableColumn("Album", value: \.album, comparator: UnknownStringComparator(unknown: "Unknown Album")) { song in
            AlbumCell(song: song)
        }
    }
    
    private var durationColumn: some TableColumnContent<Song, KeyPathComparator<Song>> {
        TableColumn("Duration", value: \.duration) { song in
            DurationCell(song: song)
        }
        .width(min: 60, ideal: 80, max: 100)
    }
    
    var body: some View {
        Table(of: Song.self, selection: $selectedSongID, sortOrder: $sortOrder) {
            trackNumberColumn
            titleColumn
            artistColumn
            albumColumn
            durationColumn
        } rows: {
            ForEach(sortedSongs) { song in
                TableRow(song)
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: false))
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .introspect(.table, on: .macOS(.v12, .v13, .v14, .v15)) { tableView in
            tableView.backgroundColor = NSColor.clear
            tableView.enclosingScrollView?.drawsBackground = false
            tableView.enclosingScrollView?.contentView.drawsBackground = false
        }
        .contextMenu(forSelectionType: Song.ID.self) { _ in
        } primaryAction: { ids in
            if let id = ids.first, let song = libraryManager.library.first(where: { $0.id == id }) {
                playbackManager.playSong(song)
            }
        }
        .onAppear {
            if libraryManager.library.isEmpty, libraryManager.musicDirectoryURL != nil {
                libraryManager.refreshLibrary()
            }
        }
    }
}
