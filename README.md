# iMusic

A macOS music player inspired by iTerm2’s transparent window with variable blur. Built with Swift and SwiftUI.

## Features
- **Customizable**: Configure colors, fonts, and more in the Settings view.
- **Transparent Window with Blur**: Uses private macOS APIs (`CGSSetWindowBackgroundBlurRadius`) for dynamic blur effects, adjustable via a slider.
- **Work in Progress**: Actively developing new features and improvements.

## Installation
- Note: requires macOS 13 Ventura or later
#### Option 1: Install release
- Download `iMusic.dmg` from the [Releases](https://github.com/charliethompson217/iMusic/releases) page.
- Mount the `.dmg` and drag `iMusic.app` to Applications.
- Note: right-click and select Open to bypass Gatekeeper.
#### Option 2: Build from source
1. Clone the repo: `git clone https://github.com/charliethompson217/iMusic.git`
2. Open `iMusic.xcodeproj` in Xcode.
3. Build and run.

## Usage
#### Ading Songs
- In the macOS menu bar, select `Library`>`Refresh Library` and chose the directory where your songs are located
- The library scan may take a moment depending on your exact hardware (it must hash every file and parse metadata)
- Songs which have duplicate hashes are only counted once
- The app will track the date added with nanosecond precision and use this as a song ID
- As long a file's path OR its hash remain the same, then its ID will also remain the same (This allows for external modifications to location OR music metadata)

#### Making Playlists
- Hit the plus button next to the library tag
- Right click a song and select `Add to playlist`>`New playlist` or `Add to playlist`>`[Playlist Name]`
- Right click a playlist tab to delete it
- Playlist simply store references to songs in your library

#### Filter and Sort Songs
- In the seach bar, filter by tittle, artist, or album (lyrics seach comming soon!)
- Erase the seach bar and the filter is completley removed so the next song will be whichever was next before the filter
- Click a table header to sort by that column, click again to reverse the order
- The order the songs are played in always matches the order of the table (unless shuffle is on)

## License
MIT License (see [LICENSE](LICENSE)).
