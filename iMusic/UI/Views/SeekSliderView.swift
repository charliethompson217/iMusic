//
//  SeekSliderView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

struct SeekSliderView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    @State private var currentTime: Double = 0.0
    @State private var isDragging: Bool = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(settings.seekSlider.trackColor)
                        .frame(width: geometry.size.width * CGFloat(currentTime / (playbackManager.currentSong?.duration ?? 1.0)), height: 4)
                    
                    if settings.seekSlider.showThumb {
                        Circle()
                            .fill(settings.seekSlider.trackColor)
                            .frame(width: settings.seekSlider.thumbSize, height: settings.seekSlider.thumbSize)
                            .offset(x: geometry.size.width * CGFloat(currentTime / (playbackManager.currentSong?.duration ?? 1.0)) - settings.seekSlider.thumbSize / 2)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let maxDuration = playbackManager.currentSong?.duration ?? 1.0
                            let newTime = max(0, min(maxDuration, Double(value.location.x / geometry.size.width) * maxDuration))
                            currentTime = newTime
                            playbackManager.setPlaybackTime(newTime)
                            print("DEBUG: Drag - newTime: \(newTime), x: \(value.location.x), width: \(geometry.size.width)")
                        }
                        .onEnded { _ in
                            isDragging = false
                            playbackManager.setPlaybackTime(currentTime)
                            print("DEBUG: Drag ended - currentTime: \(currentTime)")
                        }
                        .simultaneously(with: SpatialTapGesture()
                            .onEnded { value in
                                let maxDuration = playbackManager.currentSong?.duration ?? 1.0
                                let newTime = max(0, min(maxDuration, Double(value.location.x / geometry.size.width) * maxDuration))
                                currentTime = newTime
                                playbackManager.setPlaybackTime(newTime)
                                print("DEBUG: Tap - newTime: \(newTime), x: \(value.location.x), width: \(geometry.size.width)")
                            }
                        )
                )
            }
            .frame(height: max(settings.seekSlider.thumbSize, 4))
            
            HStack {
                Text(formatTime(currentTime))
                    .font(settings.font(for: settings.seekSlider.time.family, size: settings.seekSlider.time.size))
                    .foregroundColor(settings.seekSlider.time.color)
                Spacer()
                Text(formatTime(playbackManager.currentSong?.duration ?? 0.0))
                    .font(settings.font(for: settings.seekSlider.time.family, size: settings.seekSlider.time.size))
                    .foregroundColor(settings.seekSlider.time.color)
            }
            .padding(.horizontal)
        }
        .onAppear {
            startTimer()
            print("DEBUG: SeekSliderView appeared")
        }
        .onDisappear {
            timer?.invalidate()
            print("DEBUG: SeekSliderView disappeared")
        }
        .onChange(of: playbackManager.currentSong) { _ in
            currentTime = playbackManager.getCurrentPlaybackTime()
            startTimer()
            print("DEBUG: Current song changed, currentTime: \(currentTime)")
        }
        .onChange(of: playbackManager.isPlaying) { isPlaying in
            if isPlaying {
                startTimer()
            } else {
                timer?.invalidate()
            }
            print("DEBUG: isPlaying changed to: \(isPlaying)")
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isDragging {
                currentTime = playbackManager.getCurrentPlaybackTime()
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
