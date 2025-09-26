//
//  NewPlaylistView.swift
//  iMusic
//
//  Created by charles thompson on 9/26/25.
//

import SwiftUI

struct NewPlaylistView: View {
    @State private var name: String = ""
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Create New Playlist")
                .font(.headline)
            
            TextField("Playlist Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack(spacing: 8) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create") {
                    if !name.isEmpty {
                        onCreate(name)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
