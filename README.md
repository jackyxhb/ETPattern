# English Thought (ET) — Master 300 Expression Patterns 🧠

**English Thought (ET)** is a premium iOS spaced-repetition app designed to help learners internalize **300 core English expression patterns**. Built with SwiftUI and SwiftData, it treats language learning as a science, using an advanced SM-2 algorithm to optimize review intervals.

![iOS 17+](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![Architecture](https://img.shields.io/badge/Arch-Pure%20Xcode-green.svg)
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)

---

## ✨ Key Features (v2.1)

### 🧠 Intelligent Spaced Repetition (FSRS v4)

We've upgraded the app's brain to the **Free Spaced Repetition Scheduler (FSRS) v4**, the modern gold standard for memory retention.

- **Adaptive Scheduling**: Calculates intervals based on memory **Stability (S)** and **Difficulty (D)**, not just fixed multipliers.
- **State Tracking**: Tracks cards through `Learning`, `Review`, and `Relearning` stages.
- **Efficiency**: "Easy" cards scale rapidly (jumps of 4 days -> 15 days+), while "Hard" cards are reviewed more frequently to ensure mastery.

### 💎 "Liquid Glass" Aesthetic

A complete UI overhaul featuring a modern **Glassmorphism** design language.

- **Depth**: Multi-layer shadows and `.ultraThinMaterial` backgrounds.
- **Haptics**: Rich tactile feedback (`snap`) for every interaction (Success vs Warning).
- **Semantics**: A strict 4pt grid system and semantic color tokens via `Theme.swift`.
- **Identity**: "Seamless Titanium" App Icon with industrial-grade detailing.

### ⚡️ Data Resilience & Cloud Engine

- **SwiftData Persistence**: Fully migrated from Core Data to a robust, thread-safe SwiftData stack.
- **CloudKit Sync**:
  - **Auto-Mirroring**: Seamless cross-device synchronization (iPhone/iPad).
  - **Explicit Config**: Hardened persistence layer ensuring connection to the correct iCloud container.
  - **Status UI**: Real-time sync logs visible in `Settings > Cloud Sync`.
- **Self-Healing Import**:
  - **Auto-Repair**: Automatically detects and fixes duplicate data (>400 cards) on launch.
  - **Ghost Busters**: Smart `CSVImporter` filters out blank/malformed lines (`;;;;`) to keep decks clean.

### 🗣️ Immersive Audio

- **Event-Driven TTS**: Audio and UI are perfectly synced; the card flips only when the sentence finishes.
- **Offline Support**: High-quality neural voices work without an internet connection.

### 📱 Native iPad Experience

- **Optimized Layout**: Fully adaptive layouts properly utilize the larger canvas.
- **Sidebar Support**: Dedicated sidebar navigation for quick access to decks and tools.
- **Floating Modals**: Popovers and sheets are optimized for non-intrusive presentation (Split View ready).

---

## 🏗️ Unified Architecture (Pure Xcode)

The project follows a clean, layered architecture consolidated into a single Xcode target for maximum development efficiency.

```text
ETPattern/
├── Models/           # SwiftData Entities (Card, CardSet, ReviewLog)
├── Core/             # Pure Logic (FSRS Algorithm, Constants)
├── Services/         # I/O & Logic (TTSService, CloudSync, CSV)
├── ViewModels/       # State Management (MainActor)
├── Views/            # SwiftUI Presentation (Theme-aware)
├── Utilities/        # Extensions & Shared Helpers
├── Resources/        # Assets, Strings, and Bundled Decks
└── scripts/          # Build, Deploy, and CI automation
```

---

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 17.0+ Device/Simulator
- Swift 6.0 Toolchain

### Quick Install

The project includes automation scripts for easy deployment:

**For your primary device (iPhone 16 Plus):**

```bash
./deploy.sh
```

**Universal installer (Device or Simulator):**

```bash
./install.sh
```

### Manual Build

1. Open `ETPattern.xcodeproj`
2. Select target `ETPattern`
3. Select your destination (Device or Simulator)
4. **Cmd + R** to run.

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

### v2.2.0 - "The Brain Upgrade"

- **Algorithm**: Replaced SM-2 with **FSRS v4** (Stability/Difficulty/State tracking).
- **Cloud Sync**: Added robust configuration and sync status visibility in Settings.
- **UI**: Complete "Liquid Glass" refactor with `snap` haptics and improved dark mode support.

### v2.1.0 - "Unified & Simplified" (Legacy Refactor)

- **Architecture**: Migrated from a hybrid SPM + Xcode to a pure, monolithic Xcode project.
- **Cleanup**: Removed all `public` keywords and cross-module imports for easier internal maintenance.
- **Stability**: Fixed platform compatibility issues by removing stale macOS target declarations.

### v2.0.6

- **Fixes**: Temporarily disabled version sync script to fix build errors.

### v2.0.4

- **Branding**: Finalized "Seamless Titanium" App Icon.
- **Fixes**: Resolved CSV data corruption issues and iOS 17 deprecation warnings.
- **CI**: Enhanced CI scripts for version synchronization.

### v2.0.0 - "The Modern Era"

- **Architecture**: Initial modularization using SPM.
- **Persistence**: Migration to SwiftData + CloudKit readiness.
- **UI**: Liquid Glass redesign + "Monogram" App Icon.
- **SRS**: SM-2 Algorithm + 4-Button Grading System.

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
