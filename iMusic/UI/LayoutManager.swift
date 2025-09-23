//
//  LayoutManager.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

struct LayoutManager: View {
    @EnvironmentObject var appState: AppStateManager
    
    let geometry: GeometryProxy
    
    var body: some View {
        
        if geometry.size.width <= 200 && geometry.size.height <= 100 {
            NowPlayingView()
        } else if geometry.size.width <= 200 && geometry.size.height <= 150 {
            VStack {
                NowPlayingView()
                PlaybackButtonsView()
            }
        } else if geometry.size.width <= 500 && geometry.size.height <= 500 {
            VStack {
                NowPlayingView()
                PlaybackButtonsView()
                SeekSliderView()
            }
        } else if geometry.size.height <= 200 || geometry.size.width <= 200{
            HStack {
                VStack {
                    HStack {
                        NowPlayingView()
                        Spacer()
                        VStack {
                            PlaybackButtonsView()
                        }
                    }
                    SeekSliderView()
                }
                if appState.lyricsOpen {
                    LyricsView()
                }
            }
        } else if geometry.size.width <= 650{
            HStack {
                VStack {
                    NowPlayingView()
                    PlaybackButtonsView()
                    SeekSliderView()
                    SongTableView()
                }
                if appState.lyricsOpen {
                    LyricsView()
                }
            }
        } else {
            HStack {
                VStack {
                    HStack {
                        NowPlayingView()
                        Spacer()
                        VStack {
                            PlaybackButtonsView()
                        }
                    }
                    SeekSliderView()
                    SongTableView()
                }
                if appState.lyricsOpen {
                    LyricsView()
                }
            }
        }
    }
}
