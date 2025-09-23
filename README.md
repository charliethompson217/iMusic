# iMusic

A macOS music player inspired by iTerm2’s transparent window with variable blur. Built with Swift and SwiftUI.

## Features
- **Customizable**: Configure colors, fonts, and more in the Settings view.
- **Transparent Window with Blur**: Uses private macOS APIs (`CGSSetWindowBackgroundBlurRadius`) for dynamic blur effects, adjustable via a slider.
- **Work in Progress**: Actively developing new features and improvements.

## Installation
- Note: requires macOS 13 Ventura or later
### Option 1: Install release
- Download `iMusic.dmg` from the [Releases](https://github.com/charliethompson217/iMusic/releases) page.
- Mount the `.dmg` and drag `iMusic.app` to Applications.
- Note: right-click and select Open to bypass Gatekeeper.
### Option 2: Build from source
1. Clone the repo: `git clone https://github.com/charliethompson217/iMusic.git`
2. Open `iMusic.xcodeproj` in Xcode.
3. Build and run.

## License
MIT License (see [LICENSE](LICENSE)).
