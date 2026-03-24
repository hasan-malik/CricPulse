# CricPulse 🏏

> Live cricket scores, detailed scorecards, and the latest news — across every Apple platform.

![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=flat-square&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-17%2B-000000?style=flat-square&logo=apple&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5-FA7343?style=flat-square&logo=swift&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-2997ff?style=flat-square)

CricPulse is a native Apple-ecosystem cricket app built with SwiftUI, delivering real-time match scores, ball-by-ball scorecards, and the latest cricket news. Designed with a clean, Cricbuzz-inspired interface — white-dominant with cricket-red accents — and optimised for every screen size.

---

## Features

| Feature | Status |
|---|---|
| 🔴 Live scores with 30s auto-refresh | ✅ |
| 📊 Ball-by-ball scorecard (batting & bowling tables) | ✅ |
| 🗓 Schedule — Live Now / Upcoming / Recent Results | ✅ |
| 🏳️ Country flags & team abbreviations (IND, PAK, NZ…) | ✅ |
| 🌙 Dark / Light mode toggle with persistent preference | ✅ |
| 🎬 Animated splash screen with random cricket facts | ✅ |
| 🏏 Ambient cricket ball particle animation | ✅ |
| 📰 Latest news section with category tags | ✅ |
| ⌚ watchOS companion app | 🔜 Phase 7 |
| 🥽 visionOS spatial scoreboard | 🔜 Phase 8 |
| 📊 Swift Charts run-rate graph | 🔜 Phase 4 |
| 🏝 Live Activities + Dynamic Island | 🔜 Phase 5 |
| 🪟 WidgetKit home screen widgets | 🔜 Phase 6 |

---

## Platforms

| Platform | Minimum Version | Notes |
|---|---|---|
| iPhone | iOS 17+ | Primary target |
| iPad | iPadOS 17+ | Adaptive layout |
| Mac | macOS 14+ | Mac Catalyst |
| Apple Watch | watchOS 10+ | Phase 7 |
| Apple Vision Pro | visionOS 1+ | Phase 8 |

---

## Tech Stack

- **SwiftUI** — Declarative UI across all Apple platforms
- **SwiftData** — Persistent storage for favourites and recently viewed matches
- **@Observable** — Modern reactive state management (iOS 17+)
- **async/await + actors** — Structured concurrency for all networking
- **CricketData.org API** — Live match data, scorecards, and series info

---

## Architecture

```
CricPulse/
├── Config/
│   ├── APIConfig.example.swift   # Copy to APIConfig.swift and add your key
│   ├── CricColors.swift          # Adaptive design-token color system
│   └── PlatformHelpers.swift     # Cross-platform SwiftUI abstractions
│
├── Models/
│   ├── CricketModels.swift       # Match, Scorecard, Innings, Batsman, Bowler…
│   ├── NewsItem.swift            # News article model
│   └── TeamHelpers.swift         # Team abbreviations and flag emoji
│
├── Networking/
│   └── CricketAPIService.swift   # actor — fetchMatches, fetchScorecard, fetchSeries
│
├── ViewModels/
│   ├── MatchListViewModel.swift  # @Observable — filtering, live count, refresh
│   └── MatchDetailViewModel.swift # @Observable — scorecard, auto-refresh, innings
│
└── Views/
    ├── HomeView.swift            # Featured carousel + news feed
    ├── MatchesTabView.swift      # Live / Upcoming / Recent sections
    ├── MatchListView.swift       # Searchable flat list with filter menu
    ├── MatchDetailView.swift     # Scorecard — batting & bowling tables
    ├── NewsCard.swift            # News article card
    ├── FloatingBalls.swift       # Ambient cricket ball particle system
    └── SplashView.swift          # Animated launch splash
```

---

## Setup

### 1. Get an API Key

Sign up at [cricketdata.org](https://cricketdata.org) for a free lifetime API key.

### 2. Clone & Configure

```bash
git clone https://github.com/hasan-malik/CricPulse.git
cd CricPulse
cp CricPulse/Config/APIConfig.example.swift CricPulse/Config/APIConfig.swift
```

Open `APIConfig.swift` and replace `YOUR_CRICKETDATA_API_KEY` with your key.

### 3. Run

Open `CricPulse.xcodeproj` in Xcode 15+, select your target device, and run (`⌘R`).

> **Note:** The free API tier returns live data for current matches. Detailed ball-by-ball scorecards are available for live matches and select series.

---

## Roadmap

```
Phase 1  ✅  Core match list, scorecard, API integration
Phase 2  ✅  Home tab, news section, featured carousel
Phase 3  ✅  Cricbuzz-style white UI, dark mode, ambient animation
Phase 4  🔜  WagonWheelView (SwiftUI Canvas) + Swift Charts run-rate
Phase 5  🔜  Live Activities + Dynamic Island
Phase 6  🔜  WidgetKit home-screen widgets
Phase 7  🔜  watchOS companion with WatchConnectivity
Phase 8  🔜  visionOS spatial scoreboard (RealityKit)
Phase 9  🔜  CoreML win-probability model (Python + coremltools)
```

---

## Contributing

Issues and PRs welcome. Please branch from `main` using the convention:

```
feature/short-description   # new functionality
fix/short-description       # bug fixes
docs/short-description      # documentation
```

---

## License

MIT © Hasan Malik
