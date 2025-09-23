//
//  NowPlayingView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    
    var body: some View {
        HStack {
            if let albumArt = playbackManager.currentAlbumArt {
                Image(nsImage: albumArt)
                    .resizable()
                    .scaledToFit()
                    .frame(width: settings.nowPlaying.imageSize, height: settings.nowPlaying.imageSize)
            } else {
                Image(systemName: "star.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }
            VStack {
                Text(playbackManager.currentSong?.title ?? "No Title Available")
                    .font(settings.font(for: settings.nowPlaying.title.family, size: settings.nowPlaying.title.size))
                    .foregroundColor(settings.nowPlaying.title.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(playbackManager.currentSong?.artist ?? "No Artist Available")
                    .font(settings.font(for: settings.nowPlaying.artist.family, size: settings.nowPlaying.artist.size))
                    .foregroundColor(settings.nowPlaying.artist.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(playbackManager.currentSong?.album ?? "No Album Available")
                    .font(settings.font(for: settings.nowPlaying.album.family, size: settings.nowPlaying.album.size))
                    .foregroundColor(settings.nowPlaying.album.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
    }
}
