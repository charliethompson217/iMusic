//
//  MainView.swift
//  iMusic
//
//  Created by charles thompson on 9/22/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var settings: SettingsModel
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var appState: AppStateManager

    var body: some View {
        GeometryReader { geometry in
            VStack {
                LayoutManager(geometry: geometry)
                Spacer()
                HStack{
                    Spacer()
                    Text(playbackManager.currentFilePath ?? "No File Path Available")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    Text("\(Int(geometry.size.width))")
                        .font(.system(size: 10))
                    Text("x")
                        .font(.system(size: 10))
                    Text("\(Int(geometry.size.height))")
                        .font(.system(size: 10))
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
