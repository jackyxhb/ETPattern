# English Thought (ET) — Master 300 Expression Patterns 🧠

**English Thought (ET)** is a premium iOS spaced-repetition app designed to help learners internalize **300 core English expression patterns**. Built with SwiftUI and SwiftData, it treats language learning as a science, using an advanced SM-2 algorithm to optimize review intervals.

![iOS 17+](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![Architecture](https://img.shields.io/badge/Arch-Modular%20SPM-green.svg)
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)

---

## ✨ Key Features (v2.0)

### 🧠 Intelligent Spaced Repetition (SRS)

Upgrade from a simple binary system to a **4-Level Grading Engine** (Again, Hard, Good, Easy) powered by a custom **SM-2 Algorithm**.

- **Intelligent Queue**: Prioritizes "Due" cards first, then "New" cards, ensuring you review what matters most.
- **Detailed Metrics**: Tracks `easeFactor`, `lapses`, and `interval` for every card.
- **Session History**: All `ReviewLogs` are persisted for future analytics.

### 💎 "Liquid Glass" Aesthetic

A complete UI overhaul featuring a modern **Glassmorphism** design language.

- **Depth**: Multi-layer shadows and `.ultraThinMaterial` backgrounds.
- **Haptics**: Rich tactile feedback for every interaction (Success vs Warning).
- **Semantics**: A strict 4pt grid system and semantic color tokens via `Theme.swift`.
- **Identity**: "Seamless Titanium" App Icon with industrial-grade detailing.

### ⚡️ Data Resilience & Cloud Engine

- **SwiftData Persistence**: Fully migrated from Core Data to a robust, thread-safe SwiftData stack.
- **CloudKit Sync**: Built-in support for seamless cross-device synchronization (iPhone/iPad).
- **Self-Healing Import**:
  - **Auto-Repair**: Automatically detects and fixes duplicate data (>400 cards) on launch.
  - **Ghost Busters**: Smart `CSVImporter` filters out blank/malformed lines (`;;;;`) to keep decks clean.
  - **Race-Free**: Serialized initialization logic prevents double-import bugs.

### 🗣️ Immersive Audio

- **Event-Driven TTS**: Audio and UI are perfectly synced; the card flips only when the sentence finishes.
- **Offline Support**: High-quality neural voices work without an internet connection.

### 📱 Native iPad Experience

- **Optimized Layout**: Fully adaptive layouts properly utilizing the larger canvas.
- **Sidebar Support**: Dedicated sidebar navigation for quick access to decks and tools.
- **Floating Modals**: Popovers and sheets are optimized for non-intrusive presentation (Split View ready).

---

## 🏗️ Modular Architecture

The project has been refactored into a scalable 3-tier architecture using localized Swift Packages:

```text
ETPattern/
├── ETPatternModels/       # Domain Entities (Schema)
│   ├── Card, CardSet
│   ├── StudySession, ReviewLog
│   └── DifficultyRating
├── ETPatternCore/         # Business Logic (Pure Swift)
│   ├── SpacedRepetitionLogic (SM-2 implementation)
│   └── QueueBuilder
├── ETPatternServices/     # Application Services (IO)
│   ├── SessionManager
│   ├── CSVImporter
│   └── CloudSyncManager
└── ETPattern/             # App Composition Root (UI)
    ├── Views/ (StudyView, Dashboard, Splash)
    └── AppInitManager
```

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 16.0+ Device/Simulator
- Swift 6.0 Toolchain

### Quick Install (Device)

Connect your iPhone 16 Plus (or other device) and run:

```bash
./deploy.sh
```

This verified script builds the app using `xcodebuild` and installs it via `devicectl`.

### Manual Build

1. Open `ETPattern.xcodeproj`
2. Select target `ETPattern` > Any iOS Device (arm64)
3. **Cmd + R** to run.

---

## 📊 Data Format (CSV)

The app accepts "chunked" CSV files. Import your own decks using the following format:

`Front;;Back;;Tags`

```csv
I think...;;I think this is great.<br>I think we are ready.;;1-Opinions
I doubt...;;I doubt it will rain.<br>I doubt he knows.;;2-Skepticism
```

- **Separator**: Double semicolon `;;`
- **Newlines**: Use `<br>` for line breaks inside the "Back" field.

---

## 📜 Changelog

### v2.0.6

- **Fixes**: Temporarily disabled version sync script to fix build errors.

### v2.0.5

### v2.0.4

- **Branding**: Finalized "Seamless Titanium" App Icon.
- **Fixes**: Resolved CSV data corruption issues and iOS 17 deprecation warnings.
- **CI**: Enhanced CI scripts for version synchronization.

### v2.0.0 - "The Modern Era"

- **Architecture**: Full modularization (Models/Core/Services).
- **Persistence**: Migration to SwiftData + CloudKit readiness.
- **UI**: Liquid Glass redesign + "Monogram" App Icon.
- **SRS**: SM-2 Algorithm + 4-Button Grading System.
- **Fixes**: Resolved race conditions in seed logic & strictly filtered CSV artifacts.

### v1.8.0

- **Chinese Translations**: Native on-device translation support.
- **Unique IDs**: Global ID system to prevent duplications.

---

## 🔒 Privacy

English Thought is a privacy-first application.

- **On-Device Processing**: All learning data stays on your device (and private iCloud container).
- **No Tracking**: We do not track your usage or collect personal data.
- **Transparent**: See `index.html` for the full Privacy Policy text.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

> **Happy Learning!** Master the patterns, master the language.
