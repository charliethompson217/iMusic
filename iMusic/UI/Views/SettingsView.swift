//
//  SettingsView.swift
//  iMusic
//
//  Created by Charles Thompson on 9/22/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsModel
    @State private var expandedSections: Set<String> = []
    
    private let sectionSpacing: CGFloat = 16
    private let contentPadding: CGFloat = 16
    
    var body: some View {
        ScrollView {
            VStack(spacing: sectionSpacing) {
                ExpandableSettingsGroup(title: "Window Background", id: "windowBackground", isExpanded: isExpanded("windowBackground")) {
                    WindowBackgroundSection(settings: settings)
                }
                ExpandableSettingsGroup(title: "Lyrics", id: "lyrics", isExpanded: isExpanded("lyrics")) {
                    LyricsSection(settings: settings)
                }
                ExpandableSettingsGroup(title: "Song Table", id: "songTable", isExpanded: isExpanded("songTable")) {
                    SongTableSection(settings: settings)
                }
                ExpandableSettingsGroup(title: "Now Playing", id: "nowPlaying", isExpanded: isExpanded("nowPlaying")) {
                    NowPlayingSection(settings: settings)
                }
                ExpandableSettingsGroup(title: "Seek Slider", id: "seekSlider", isExpanded: isExpanded("seekSlider")) {
                    SeekSliderSection(settings: settings)
                }
            }
            .padding(contentPadding)
        }
        .frame(minWidth: 400, minHeight: 600)
    }
    
    private func isExpanded(_ id: String) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedSections.insert(id)
                } else {
                    expandedSections.remove(id)
                }
            }
        )
    }
}

private struct WindowBackgroundSection: View {
    @ObservedObject var settings: SettingsModel
    
    var body: some View {
        VStack(spacing: 12) {
            SettingsSliderView(label: "Blur Radius", value: $settings.window.background.blur, range: 0...100, step: 1)
            SettingsSliderView(label: "Red", value: $settings.window.background.red, range: 0...255, step: 1)
            SettingsSliderView(label: "Green", value: $settings.window.background.green, range: 0...255, step: 1)
            SettingsSliderView(label: "Blue", value: $settings.window.background.blue, range: 0...255, step: 1)
            SettingsSliderView(label: "Alpha", value: $settings.window.background.alpha, range: 0...1, step: 0.01)
        }
        .padding(.vertical, 8)
    }
}

private struct LyricsSection: View {
    @ObservedObject var settings: SettingsModel
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("Font Family", selection: $settings.lyrics.font.family) {
                ForEach(settings.availableFonts, id: \.self) { font in
                    Text(font).tag(font)
                }
            }
            .pickerStyle(MenuPickerStyle())
            SettingsSliderView(label: "Font Size", value: $settings.lyrics.font.size, range: 8...36, step: 1)
            ColorPicker("Font Color", selection: $settings.lyrics.font.color)
            SettingsSliderView(label: "Padding", value: $settings.lyrics.padding, range: 0...20, step: 1)
        }
        .padding(.vertical, 8)
    }
}

private struct SongTableSection: View {
    @ObservedObject var settings: SettingsModel
    
    var body: some View {
        VStack(spacing: 12) {
            FontSettingsSection(title: "Track Number", family: $settings.songTable.trackNumber.family,
                             size: $settings.songTable.trackNumber.size, color: $settings.songTable.trackNumber.color, availableFonts: settings.availableFonts)
            Toggle("Show Album Image", isOn: $settings.songTable.albumImage)
            FontSettingsSection(title: "Title", family: $settings.songTable.title.family,
                             size: $settings.songTable.title.size, color: $settings.songTable.title.color, availableFonts: settings.availableFonts)
            FontSettingsSection(title: "Artist", family: $settings.songTable.artist.family,
                             size: $settings.songTable.artist.size, color: $settings.songTable.artist.color, availableFonts: settings.availableFonts)
            FontSettingsSection(title: "Album", family: $settings.songTable.album.family,
                             size: $settings.songTable.album.size, color: $settings.songTable.album.color, availableFonts: settings.availableFonts)
            FontSettingsSection(title: "Duration", family: $settings.songTable.duration.family,
                             size: $settings.songTable.duration.size, color: $settings.songTable.duration.color, availableFonts: settings.availableFonts)
            ColorPicker("Background Color", selection: $settings.songTable.backgroundColor)
            ColorPicker("Selected Item Highlight", selection: $settings.songTable.selectedItemHighlightColor)
        }
        .padding(.vertical, 8)
    }
}

private struct NowPlayingSection: View {
    @ObservedObject var settings: SettingsModel
    
    var body: some View {
        VStack(spacing: 12) {
            FontSettingsSection(title: "Title", family: $settings.nowPlaying.title.family,
                             size: $settings.nowPlaying.title.size, color: $settings.nowPlaying.title.color, availableFonts: settings.availableFonts)
            FontSettingsSection(title: "Artist", family: $settings.nowPlaying.artist.family,
                             size: $settings.nowPlaying.artist.size, color: $settings.nowPlaying.artist.color, availableFonts: settings.availableFonts)
            FontSettingsSection(title: "Album", family: $settings.nowPlaying.album.family,
                             size: $settings.nowPlaying.album.size, color: $settings.nowPlaying.album.color, availableFonts: settings.availableFonts)
            SettingsSliderView(label: "Image Size", value: $settings.nowPlaying.imageSize, range: 50...300, step: 1)
        }
        .padding(.vertical, 8)
    }
}

private struct SeekSliderSection: View {
    @ObservedObject var settings: SettingsModel
    
    var body: some View {
        VStack(spacing: 12) {
            FontSettingsSection(title: "Time", family: $settings.seekSlider.time.family,
                             size: $settings.seekSlider.time.size, color: $settings.seekSlider.time.color, availableFonts: settings.availableFonts)
            Toggle("Show Thumb", isOn: $settings.seekSlider.showThumb)
            ColorPicker("Track Color", selection: $settings.seekSlider.trackColor)
            SettingsSliderView(label: "Thumb Size", value: $settings.seekSlider.thumbSize, range: 8...24, step: 1)
        }
        .padding(.vertical, 8)
    }
}

private struct ExpandableSettingsGroup<Content: View>: View {
    let title: String
    let id: String
    @Binding var isExpanded: Bool
    let content: Content
    
    init(title: String, id: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.id = id
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
        } label: {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

private struct FontSettingsSection: View {
    let title: String
    @Binding var family: String
    @Binding var size: Double
    @Binding var color: Color
    let availableFonts: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title).font(.headline)
            Picker("Font Family", selection: $family) {
                ForEach(availableFonts, id: \.self) { font in
                    Text(font).tag(font)
                }
            }
            .pickerStyle(MenuPickerStyle())
            SettingsSliderView(label: "Font Size", value: $size, range: 8...36, step: 1)
            ColorPicker("Font Color", selection: $color)
        }
    }
}
