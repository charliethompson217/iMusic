//
//  LibraryBrowserView.swift
//  iMusic
//
//  Created by charles thompson on 9/26/25.
//

import SwiftUI
import AppKit
@_spi(Advanced) import SwiftUIIntrospect

struct DisplaySong: Identifiable {
    let song: LibraryManager.Song
    var trackNumber: Int
    
    var id: Date { song.id }
    var title: String { song.title }
    var artist: String? { song.artist }
    var album: String? { song.album }
    var duration: Double { song.duration }
}

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
    let displaySong: DisplaySong
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text("\(displaySong.trackNumber)")
            .font(settings.font(for: settings.songTable.trackNumber.family, size: settings.songTable.trackNumber.size))
            .foregroundColor(settings.songTable.trackNumber.color)
    }
}

struct TitleCell: View {
    let displaySong: DisplaySong
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(displaySong.title)
            .font(settings.font(for: settings.songTable.title.family, size: settings.songTable.title.size))
            .foregroundColor(settings.songTable.title.color)
    }
}

struct ArtistCell: View {
    let displaySong: DisplaySong
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(displaySong.artist ?? "Unknown Artist")
            .font(settings.font(for: settings.songTable.artist.family, size: settings.songTable.artist.size))
            .foregroundColor(settings.songTable.artist.color)
    }
}

struct AlbumCell: View {
    let displaySong: DisplaySong
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(displaySong.album ?? "Unknown Album")
            .font(settings.font(for: settings.songTable.album.family, size: settings.songTable.album.size))
            .foregroundColor(settings.songTable.album.color)
    }
}

struct DurationCell: View {
    let displaySong: DisplaySong
    @EnvironmentObject var settings: SettingsModel
    
    var body: some View {
        Text(formatDuration(displaySong.duration))
            .font(settings.font(for: settings.songTable.duration.family, size: settings.songTable.duration.size))
            .foregroundColor(settings.songTable.duration.color)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

enum ViewMode: Equatable {
    case library
    case playlist(UUID)
}

struct LibraryBrowserView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager
    
    @State private var currentView: ViewMode = .library
    @State private var selectedSongIDs: Set<Date> = []
    @State private var sortOrder: [KeyPathComparator<DisplaySong>] = [KeyPathComparator(\.title)]
    @State private var searchText: String = ""
    @State private var showCreatePlaylist: Bool = false
    @State private var songsToAddAfterCreate: [LibraryManager.Song]? = nil
    
    private var currentSongs: [DisplaySong] {
        switch currentView {
        case .library:
            return libraryManager.library.map { DisplaySong(song: $0, trackNumber: $0.trackNumber) }
        case .playlist(let playlistID):
            if let playlist = libraryManager.playlists.first(where: { $0.id == playlistID }) {
                return playlist.songs.compactMap { ps in
                    guard let song = libraryManager.library.first(where: { $0.id == ps.songID }) else { return nil }
                    return DisplaySong(song: song, trackNumber: ps.trackNumber)
                }
            } else {
                return []
            }
        }
    }
    
    private var filteredSongs: [DisplaySong] {
        currentSongs.filter { displaySong in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            return displaySong.title.lowercased().contains(query) ||
                   (displaySong.artist?.lowercased().contains(query) ?? false) ||
                   (displaySong.album?.lowercased().contains(query) ?? false)
        }
    }
    
    private var displayedSongs: [DisplaySong] {
        filteredSongs.sorted(using: sortOrder)
    }
    
    private var currentPlaylistID: UUID? {
        if case .playlist(let id) = currentView {
            return id
        }
        return nil
    }
    
    private var currentPlaylistName: String? {
        if let id = currentPlaylistID, let playlist = libraryManager.playlists.first(where: { $0.id == id }) {
            return playlist.name
        }
        return nil
    }
    
    private var trackNumberColumn: some TableColumnContent<DisplaySong, KeyPathComparator<DisplaySong>> {
        TableColumn("#", value: \.trackNumber) { displaySong in
            TrackNumberCell(displaySong: displaySong)
        }
        .width(min: 40, ideal: 50, max: 60)
    }
    
    private var titleColumn: some TableColumnContent<DisplaySong, KeyPathComparator<DisplaySong>> {
        TableColumn("Title", value: \.title) { displaySong in
            TitleCell(displaySong: displaySong)
        }
    }
    
    private var artistColumn: some TableColumnContent<DisplaySong, KeyPathComparator<DisplaySong>> {
        TableColumn("Artist", value: \.artist, comparator: UnknownStringComparator(unknown: "Unknown Artist")) { displaySong in
            ArtistCell(displaySong: displaySong)
        }
    }
    
    private var albumColumn: some TableColumnContent<DisplaySong, KeyPathComparator<DisplaySong>> {
        TableColumn("Album", value: \.album, comparator: UnknownStringComparator(unknown: "Unknown Album")) { displaySong in
            AlbumCell(displaySong: displaySong)
        }
    }
    
    private var durationColumn: some TableColumnContent<DisplaySong, KeyPathComparator<DisplaySong>> {
        TableColumn("Duration", value: \.duration) { displaySong in
            DurationCell(displaySong: displaySong)
        }
        .width(min: 60, ideal: 80, max: 100)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    TabButton(title: "Library", isSelected: currentView == .library) {
                        currentView = .library
                    }
                    ForEach(libraryManager.playlists) { playlist in
                        TabButton(title: playlist.name, isSelected: currentView == .playlist(playlist.id)) {
                            currentView = .playlist(playlist.id)
                        }
                        .contextMenu {
                            Button("Delete") {
                                libraryManager.deletePlaylist(id: playlist.id)
                                if case .playlist(let currentID) = currentView, currentID == playlist.id {
                                    currentView = .library
                                }
                            }
                        }
                    }
                    Button("+") {
                        songsToAddAfterCreate = nil
                        showCreatePlaylist = true
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .foregroundColor(.primary)
                    .cornerRadius(4)
                }
                .padding(.horizontal)
            }
            
            HStack {
                TextField("Search by title, artist, or album...", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .background(Color.clear)
                    .onSubmit { }
            }
            .padding(.horizontal)
            
            Table(of: DisplaySong.self, selection: $selectedSongIDs, sortOrder: $sortOrder) {
                trackNumberColumn
                titleColumn
                artistColumn
                albumColumn
                durationColumn
            } rows: {
                ForEach(displayedSongs) { displaySong in
                    TableRow(displaySong)
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
            .contextMenu(forSelectionType: Date.self) { selectedIDs in
                Menu("Add to playlist") {
                    ForEach(libraryManager.playlists) { playlist in
                        Button(playlist.name) {
                            let selectedSongs = displayedSongs.filter { selectedIDs.contains($0.id) }.map(\.song)
                            libraryManager.addSongs(selectedSongs, to: playlist.id)
                        }
                    }
                    Button("New playlist...") {
                        songsToAddAfterCreate = displayedSongs.filter { selectedIDs.contains($0.id) }.map(\.song)
                        showCreatePlaylist = true
                    }
                }
                if let playlistID = currentPlaylistID, let playlistName = currentPlaylistName {
                    Button("Remove from \(playlistName)") {
                        libraryManager.removeSongsFromPlaylist(Array(selectedIDs), playlistID: playlistID)
                    }
                }
            } primaryAction: { ids in
                if let id = ids.first, let displaySong = displayedSongs.first(where: { $0.id == id }) {
                    playbackManager.playSong(displaySong.song, initialPlaylist: currentSongs.map(\.song))
                }
            }
        }
        .onAppear {
            if libraryManager.library.isEmpty, libraryManager.musicDirectoryURL != nil {
                libraryManager.refreshLibrary()
            }
        }
        .onChange(of: currentView) { _ in
            selectedSongIDs = []
            searchText = ""
            switch currentView {
            case .library:
                sortOrder = [KeyPathComparator(\.title)]
            case .playlist:
                sortOrder = [KeyPathComparator(\.trackNumber)]
            }
            playbackManager.updateCurrentPlaylist(currentSongs.map(\.song))
        }
        .onChange(of: sortOrder) { _ in
            playbackManager.updateCurrentPlaylist(displayedSongs.map(\.song))
        }
        .onChange(of: searchText) { _ in
            playbackManager.updateCurrentPlaylist(displayedSongs.map(\.song))
        }
        .sheet(isPresented: $showCreatePlaylist) {
            NewPlaylistView { name in
                libraryManager.createPlaylist(name: name)
                if let songs = songsToAddAfterCreate, let newPlaylist = libraryManager.playlists.last {
                    libraryManager.addSongs(songs, to: newPlaylist.id)
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.blue : Color.clear)
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(4)
    }
}
