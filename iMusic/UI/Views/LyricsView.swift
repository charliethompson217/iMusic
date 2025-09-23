//
//  LyricsView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI
import AppKit

struct LyricsView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    
    @State private var currentWidth: CGFloat = 321
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 1)
            }
            .frame(width: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newWidth = currentWidth - value.translation.width
                        currentWidth = max(100, min(600, newWidth))
                    }
            )
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                Text(playbackManager.currentLyrics ?? "No lyrics available")
                    .font(settings.font(for: settings.lyrics.font.family, size: settings.lyrics.font.size))
                    .foregroundColor(settings.lyrics.font.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: currentWidth)
        }
    }
}
