//
//  PlaybackButtonsView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

struct PlaybackButtonsView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var appState: AppStateManager
    
    var body: some View {
        HStack {
            Button(action: { playbackManager.previousSong() }) {
                Image(systemName: "backward.end.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { playbackManager.playPause() }) {
                Image(systemName: playbackManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { playbackManager.nextSong() }) {
                Image(systemName: "forward.end.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { playbackManager.toggleShuffle() }) {
                Image(systemName: "shuffle.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(playbackManager.isShuffleEnabled ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { appState.lyricsOpen.toggle() }) {
                Image(systemName: appState.lyricsOpen ? "music.note.list" : "music.note")
                    .font(.largeTitle)
                    .foregroundStyle(appState.lyricsOpen ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
