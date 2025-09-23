//
//  SettingsModel.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import Foundation
import SwiftUI
import Combine
import AppKit

@MainActor
class SettingsModel: ObservableObject {
   let availableFonts: [String] = [
       "Helvetica",
       "Arial",
       "Times New Roman",
       "Courier New",
       "Verdana",
       "Georgia",
       "Palatino",
       "Gill Sans",
       "Futura",
       "Optima"
   ]
   
   struct CodableColor: Codable {
       let red: Double
       let green: Double
       let blue: Double
       let opacity: Double
       
       init(color: Color) {
           let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
           var red: CGFloat = 0
           var green: CGFloat = 0
           var blue: CGFloat = 0
           var alpha: CGFloat = 0
           nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
           self.red = Double(red)
           self.green = Double(green)
           self.blue = Double(blue)
           self.opacity = Double(alpha)
       }
       
       var color: Color {
           Color(red: red, green: green, blue: blue, opacity: opacity)
       }
   }
   
   struct WindowSettings {
       struct Background {
           var red: Double
           var green: Double
           var blue: Double
           var alpha: Double
           var blur: Double
       }
       
       var background: Background
   }
   
   struct LyricsSettings {
       struct FontSettings {
           var family: String
           var size: Double
           var color: Color
       }
       
       var font: FontSettings
       var padding: Double
   }
   
   struct SongTableSettings {
       struct FontSettings {
           var family: String
           var size: Double
           var color: Color
       }
       
       var trackNumber: FontSettings
       var albumImage: Bool
       var title: FontSettings
       var artist: FontSettings
       var album: FontSettings
       var duration: FontSettings
       var backgroundColor: Color
       var selectedItemHighlightColor: Color
   }
   
   struct NowPlayingSettings {
       struct FontSettings {
           var family: String
           var size: Double
           var color: Color
       }
       
       var title: FontSettings
       var artist: FontSettings
       var album: FontSettings
       var imageSize: Double
   }
   
   struct SeekSliderSettings {
       struct FontSettings {
           var family: String
           var size: Double
           var color: Color
       }
       
       var time: FontSettings
       var showThumb: Bool
       var trackColor: Color
       var thumbSize: Double
   }
   
   @Published var window: WindowSettings = WindowSettings(
       background: WindowSettings.Background(
           red: 255,
           green: 255,
           blue: 255,
           alpha: 0.5,
           blur: 20
       )
   ) {
       didSet { saveSettings(); updateWindow() }
   }
   
   @Published var lyrics: LyricsSettings = LyricsSettings(
       font: LyricsSettings.FontSettings(
           family: "Helvetica",
           size: 14,
           color: .gray
       ),
       padding: 8
   ) {
       didSet { saveSettings() }
   }
   
   @Published var songTable: SongTableSettings = SongTableSettings(
       trackNumber: SongTableSettings.FontSettings(
           family: "Helvetica",
           size: 12,
           color: .gray
       ),
       albumImage: true,
       title: SongTableSettings.FontSettings(
           family: "Helvetica",
           size: 14,
           color: .gray
       ),
       artist: SongTableSettings.FontSettings(
           family: "Helvetica",
           size: 12,
           color: .gray
       ),
       album: SongTableSettings.FontSettings(
           family: "Helvetica",
           size: 12,
           color: .gray
       ),
       duration: SongTableSettings.FontSettings(
           family: "Helvetica",
           size: 12,
           color: .gray
       ),
       backgroundColor: .white,
       selectedItemHighlightColor: Color(red: 0, green: 0.478, blue: 1, opacity: 0.2)
   ) {
       didSet { saveSettings() }
   }
   
   @Published var nowPlaying: NowPlayingSettings = NowPlayingSettings(
       title: NowPlayingSettings.FontSettings(
           family: "Helvetica",
           size: 16,
           color: .gray
       ),
       artist: NowPlayingSettings.FontSettings(
           family: "Helvetica",
           size: 14,
           color: .gray
       ),
       album: NowPlayingSettings.FontSettings(
           family: "Helvetica",
           size: 14,
           color: .gray
       ),
       imageSize: 50
   ) {
       didSet { saveSettings() }
   }
   
   @Published var seekSlider: SeekSliderSettings = SeekSliderSettings(
       time: SeekSliderSettings.FontSettings(
           family: "Helvetica",
           size: 12,
           color: .gray
       ),
       showThumb: true,
       trackColor: Color(red: 0, green: 0.478, blue: 1),
       thumbSize: 12
   ) {
       didSet { saveSettings() }
   }

   private weak var blurWindow: BlurWindow?

   init(blurWindow: BlurWindow?) {
       self.blurWindow = blurWindow
       loadSettings()
       updateWindow()
   }
   
   func font(for family: String, size: Double) -> Font {
       let validFamily = availableFonts.contains(family) ? family : "Helvetica"
       return Font.custom(validFamily, size: CGFloat(size))
   }

   private func loadSettings() {
       let defaults = UserDefaults.standard
       
       // Window Settings
       let blur = defaults.double(forKey: "window.background.blur")
       let red = defaults.double(forKey: "window.background.red")
       let green = defaults.double(forKey: "window.background.green")
       let blue = defaults.double(forKey: "window.background.blue")
       let alpha = defaults.double(forKey: "window.background.alpha")
       
       window.background.blur = blur == 0 ? 20 : blur
       window.background.red = red == 0 ? 255 : red
       window.background.green = green == 0 ? 255 : green
       window.background.blue = blue == 0 ? 255 : blue
       window.background.alpha = alpha == 0 ? 0.5 : alpha
       
       // Lyrics Settings
       let lyricsFontFamily = defaults.string(forKey: "lyrics.font.family") ?? "Helvetica"
       lyrics.font.family = availableFonts.contains(lyricsFontFamily) ? lyricsFontFamily : "Helvetica"
       lyrics.font.size = defaults.double(forKey: "lyrics.font.size") == 0 ? 14 : defaults.double(forKey: "lyrics.font.size")
       lyrics.font.color = (defaults.data(forKey: "lyrics.font.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .black
       lyrics.padding = defaults.double(forKey: "lyrics.padding") == 0 ? 8 : defaults.double(forKey: "lyrics.padding")
       
       // Song Table Settings
       let trackNumberFamily = defaults.string(forKey: "songTable.trackNumber.family") ?? "Helvetica"
       songTable.trackNumber.family = availableFonts.contains(trackNumberFamily) ? trackNumberFamily : "Helvetica"
       songTable.trackNumber.size = defaults.double(forKey: "songTable.trackNumber.size") == 0 ? 12 : defaults.double(forKey: "songTable.trackNumber.size")
       songTable.trackNumber.color = (defaults.data(forKey: "songTable.trackNumber.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       
       songTable.albumImage = defaults.object(forKey: "songTable.albumImage") as? Bool ?? true
       
       let titleFamily = defaults.string(forKey: "songTable.title.family") ?? "Helvetica"
       songTable.title.family = availableFonts.contains(titleFamily) ? titleFamily : "Helvetica"
       songTable.title.size = defaults.double(forKey: "songTable.title.size") == 0 ? 14 : defaults.double(forKey: "songTable.title.size")
       songTable.title.color = (defaults.data(forKey: "songTable.title.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .black
       
       let artistFamily = defaults.string(forKey: "songTable.artist.family") ?? "Helvetica"
       songTable.artist.family = availableFonts.contains(artistFamily) ? artistFamily : "Helvetica"
       songTable.artist.size = defaults.double(forKey: "songTable.artist.size") == 0 ? 12 : defaults.double(forKey: "songTable.artist.size")
       songTable.artist.color = (defaults.data(forKey: "songTable.artist.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       
       let albumFamily = defaults.string(forKey: "songTable.album.family") ?? "Helvetica"
       songTable.album.family = availableFonts.contains(albumFamily) ? albumFamily : "Helvetica"
       songTable.album.size = defaults.double(forKey: "songTable.album.size") == 0 ? 12 : defaults.double(forKey: "songTable.album.size")
       songTable.album.color = (defaults.data(forKey: "songTable.album.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       
       let durationFamily = defaults.string(forKey: "songTable.duration.family") ?? "Helvetica"
       songTable.duration.family = availableFonts.contains(durationFamily) ? durationFamily : "Helvetica"
       songTable.duration.size = defaults.double(forKey: "songTable.duration.size") == 0 ? 12 : defaults.double(forKey: "songTable.duration.size")
       songTable.duration.color = (defaults.data(forKey: "songTable.duration.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       
       songTable.backgroundColor = (defaults.data(forKey: "songTable.backgroundColor").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .white
       
       songTable.selectedItemHighlightColor = (defaults.data(forKey: "songTable.selectedItemHighlightColor").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? Color(red: 0, green: 0.478, blue: 1, opacity: 0.2)
       
       // Now Playing Settings
       let nowPlayingTitleFamily = defaults.string(forKey: "nowPlaying.title.family") ?? "Helvetica"
       nowPlaying.title.family = availableFonts.contains(nowPlayingTitleFamily) ? nowPlayingTitleFamily : "Helvetica"
       nowPlaying.title.size = defaults.double(forKey: "nowPlaying.title.size") == 0 ? 16 : defaults.double(forKey: "nowPlaying.title.size")
       nowPlaying.title.color = (defaults.data(forKey: "nowPlaying.title.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .black
       
       let nowPlayingArtistFamily = defaults.string(forKey: "nowPlaying.artist.family") ?? "Helvetica"
       nowPlaying.artist.family = availableFonts.contains(nowPlayingArtistFamily) ? nowPlayingArtistFamily : "Helvetica"
       nowPlaying.artist.size = defaults.double(forKey: "nowPlaying.artist.size") == 0 ? 14 : defaults.double(forKey: "nowPlaying.artist.size")
       nowPlaying.artist.color = (defaults.data(forKey: "nowPlaying.artist.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       
       let nowPlayingAlbumFamily = defaults.string(forKey: "nowPlaying.album.family") ?? "Helvetica"
       nowPlaying.album.family = availableFonts.contains(nowPlayingAlbumFamily) ? nowPlayingAlbumFamily : "Helvetica"
       nowPlaying.album.size = defaults.double(forKey: "nowPlaying.album.size") == 0 ? 14 : defaults.double(forKey: "nowPlaying.album.size")
       nowPlaying.album.color = (defaults.data(forKey: "nowPlaying.album.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       nowPlaying.imageSize = defaults.double(forKey: "nowPlaying.imageSize") == 0 ? 50 : defaults.double(forKey: "nowPlaying.imageSize")
       
       // Seek Slider Settings
       let seekSliderTimeFamily = defaults.string(forKey: "seekSlider.time.family") ?? "Helvetica"
       seekSlider.time.family = availableFonts.contains(seekSliderTimeFamily) ? seekSliderTimeFamily : "Helvetica"
       seekSlider.time.size = defaults.double(forKey: "seekSlider.time.size") == 0 ? 12 : defaults.double(forKey: "seekSlider.time.size")
       seekSlider.time.color = (defaults.data(forKey: "seekSlider.time.color").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? .gray
       
       seekSlider.showThumb = defaults.object(forKey: "seekSlider.showThumb") as? Bool ?? true
       seekSlider.trackColor = (defaults.data(forKey: "seekSlider.trackColor").flatMap {
           try? JSONDecoder().decode(CodableColor.self, from: $0)
       })?.color ?? Color(red: 0, green: 0.478, blue: 1)
       seekSlider.thumbSize = defaults.double(forKey: "seekSlider.thumbSize") == 0 ? 12 : defaults.double(forKey: "seekSlider.thumbSize")
   }

   private func saveSettings() {
       let defaults = UserDefaults.standard
       
       // Window Settings
       defaults.set(window.background.blur, forKey: "window.background.blur")
       defaults.set(window.background.red, forKey: "window.background.red")
       defaults.set(window.background.green, forKey: "window.background.green")
       defaults.set(window.background.blue, forKey: "window.background.blue")
       defaults.set(window.background.alpha, forKey: "window.background.alpha")
       
       // Lyrics Settings
       defaults.set(lyrics.font.family, forKey: "lyrics.font.family")
       defaults.set(lyrics.font.size, forKey: "lyrics.font.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: lyrics.font.color)) {
           defaults.set(colorData, forKey: "lyrics.font.color")
       }
       defaults.set(lyrics.padding, forKey: "lyrics.padding")
       
       // Song Table Settings
       defaults.set(songTable.trackNumber.family, forKey: "songTable.trackNumber.family")
       defaults.set(songTable.trackNumber.size, forKey: "songTable.trackNumber.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.trackNumber.color)) {
           defaults.set(colorData, forKey: "songTable.trackNumber.color")
       }
       
       defaults.set(songTable.albumImage, forKey: "songTable.albumImage")
       
       defaults.set(songTable.title.family, forKey: "songTable.title.family")
       defaults.set(songTable.title.size, forKey: "songTable.title.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.title.color)) {
           defaults.set(colorData, forKey: "songTable.title.color")
       }
       
       defaults.set(songTable.artist.family, forKey: "songTable.artist.family")
       defaults.set(songTable.artist.size, forKey: "songTable.artist.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.artist.color)) {
           defaults.set(colorData, forKey: "songTable.artist.color")
       }
       
       defaults.set(songTable.album.family, forKey: "songTable.album.family")
       defaults.set(songTable.album.size, forKey: "songTable.album.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.album.color)) {
           defaults.set(colorData, forKey: "songTable.album.color")
       }
       
       defaults.set(songTable.duration.family, forKey: "songTable.duration.family")
       defaults.set(songTable.duration.size, forKey: "songTable.duration.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.duration.color)) {
           defaults.set(colorData, forKey: "songTable.duration.color")
       }
       
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.backgroundColor)) {
           defaults.set(colorData, forKey: "songTable.backgroundColor")
       }
       
       if let colorData = try? JSONEncoder().encode(CodableColor(color: songTable.selectedItemHighlightColor)) {
           defaults.set(colorData, forKey: "songTable.selectedItemHighlightColor")
       }
       
       // Now Playing Settings
       defaults.set(nowPlaying.title.family, forKey: "nowPlaying.title.family")
       defaults.set(nowPlaying.title.size, forKey: "nowPlaying.title.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: nowPlaying.title.color)) {
           defaults.set(colorData, forKey: "nowPlaying.title.color")
       }
       
       defaults.set(nowPlaying.artist.family, forKey: "nowPlaying.artist.family")
       defaults.set(nowPlaying.artist.size, forKey: "nowPlaying.artist.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: nowPlaying.artist.color)) {
           defaults.set(colorData, forKey: "nowPlaying.artist.color")
       }
       
       defaults.set(nowPlaying.album.family, forKey: "nowPlaying.album.family")
       defaults.set(nowPlaying.album.size, forKey: "nowPlaying.album.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: nowPlaying.album.color)) {
           defaults.set(colorData, forKey: "nowPlaying.album.color")
       }
       defaults.set(nowPlaying.imageSize, forKey: "nowPlaying.imageSize")
       
       // Seek Slider Settings
       defaults.set(seekSlider.time.family, forKey: "seekSlider.time.family")
       defaults.set(seekSlider.time.size, forKey: "seekSlider.time.size")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: seekSlider.time.color)) {
           defaults.set(colorData, forKey: "seekSlider.time.color")
       }
       
       defaults.set(seekSlider.showThumb, forKey: "seekSlider.showThumb")
       if let colorData = try? JSONEncoder().encode(CodableColor(color: seekSlider.trackColor)) {
           defaults.set(colorData, forKey: "seekSlider.trackColor")
       }
       defaults.set(seekSlider.thumbSize, forKey: "seekSlider.thumbSize")
   }

   private func updateWindow() {
       blurWindow?.setBlurRadius(Int(window.background.blur))
       if let contentView = blurWindow?.contentView {
           contentView.wantsLayer = true
           let color = NSColor(
               red: window.background.red / 255.0,
               green: window.background.green / 255.0,
               blue: window.background.blue / 255.0,
               alpha: window.background.alpha
           )
           contentView.layer?.backgroundColor = color.cgColor
       }
   }
}
