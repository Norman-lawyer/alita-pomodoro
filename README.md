# Lolita Pomodoro 🍅

A beautiful, minimalist Pomodoro timer app for macOS, built with SwiftUI.

![App Icon](LolitaPomodoro/Resources/AppIcon.icns)

## Features

- 🍅 **Pomodoro Timer** - Classic 25-minute focus sessions
- ⏰ **Timer Modes** - Pomodoro, Short Break, Long Break, and Count-up
- 🎵 **Ambient Sounds** - Rain, Forest, Ocean, Cafe, Ticking
- 🔔 **Notifications** - Gentle alerts when sessions end
- 📊 **Statistics** - Track your focus history
- 🌓 **Theme** - Dark/Light mode support
- ⚙️ **Customizable** - Adjust durations, sounds, and more

## Requirements

- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+

## Installation

### Build from Source

```bash
# Clone the repository
git clone https://github.com/Norman-lawyer/lolita-pomodoro.git
cd lolita-pomodoro

# Generate Xcode project
./setup.sh

# Open in Xcode
open LolitaPomodoro.xcodeproj

# Build and run (⌘+R)
```

### Download Pre-built App

Download the latest release from [GitHub Releases](https://github.com/Norman-lawyer/lolita-pomodoro/releases)

## Usage

1. Click the timer display to start/pause
2. Use the slider or buttons to switch modes
3. Adjust settings via the Settings panel
4. View statistics in the Stats tab

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` | Start/Pause |
| `⌘+Q` | Quit |
| `⌘+,` | Preferences |

## Project Structure

```
pomodoro-mac/
├── LolitaPomodoro/
│   ├── Sources/
│   │   ├── LolitaPomodoroApp.swift      # App entry point
│   │   ├── ContentView.swift            # Main UI
│   │   ├── PomodoroTimer.swift          # Timer logic
│   │   ├── SettingsView.swift           # Settings panel
│   │   ├── StatsView.swift              # Statistics view
│   │   ├── AudioManager.swift           # Sound management
│   │   └── TimerMode.swift              # Timer modes
│   └── Resources/
│       ├── AppIcon.icns                 # App icon
│       └── Sounds/                      # Ambient sounds
├── LolitaPomodoro.xcodeproj/            # Xcode project
├── setup.sh                             # Build script
└── project.yml                          # XcodeGen config
```

## Technologies

- **SwiftUI** - Modern declarative UI framework
- **Swift** - Apple's programming language
- **Xcode** - IDE and build system
- **XcodeGen** - Project generation

## Author

**Norman (牛炬钦)** - [Norman-lawyer](https://github.com/Norman-lawyer)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the [Pomodoro Technique](https://francescocirillo.com/pages/pomodoro-technique)
- Ambient sounds from various creative commons sources
