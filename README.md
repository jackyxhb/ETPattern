# English Thought (ET) — Master 300 Expression Patterns 🧠

**English Thought (ET)** is a premium iOS spaced-repetition app designed to help learners internalize **300 core English expression patterns**. Built with SwiftUI and SwiftData, it treats language learning as a science, using an advanced FSRS algorithm to optimize review intervals within a state-of-the-art 2026 design language.

![iOS 18+](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![Architecture](https://img.shields.io/badge/Arch-MVVM%2B-green.svg)
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)

---

## ✨ Key Features (v2.3)

### 🧩 Bento Grid Architecture

A complete dashboard redesign following the **Modern iOS "Liquid & Grid" System**.

- **Modularity**: Views are built as independent "Tiles" within a flexible Bento Grid.
- **Auto Play Flow**: A dedicated high-priority tile automatically finds the best deck and starts an automated session instantly.
- **Simplified Navigation**: Removed manual clutter (manual deck input) to focus on pure learning efficiency.

### 💎 Refined "Liquid Glass" Aesthetic

Utilizes the **Liquid Glass** aesthetic (2026 spec) for maximum visual depth and premium feel.

- **Material Depth**: Consistent `.ultraThinMaterial` backgrounds with subtle inner strokes.
- **Squircle Standards**: Standardized **28pt** primary containers and **20pt** nested elements.
- **Focused Themes**: Removed "System" theme choice to provide two manually tuned, high-performance visions: **Dark** and **Light**.
- **Interactive Motion**: Fluid, interruptible spring animations for all transitions.

### 🧠 Intelligent Spaced Repetition (FSRS v4.5)

The modern gold standard for card scheduling.

- **Adaptive Scheduling**: Calculates intervals based on memory **Stability (S)** and **Difficulty (D)**.
- **Efficiency**: "Easy" cards scale rapidly while "Hard" items are surfaced with precision to ensure 90%+ retention.

### ⚡️ Data Resilience & Cloud Engine

- **SwiftData Persistence**: Robust, thread-safe persistence with CloudKit auto-mirroring.
- **Private by Design**: All data stays in your private iCloud container; no third-party tracking.
- **Self-Healing**: Automatic duplicate detection and malformed CSV repair on launch.

---

## 🏗️ Architecture: MVVM+ (2026 Spec)

The project adheres to a strict **MVVM+** pattern, decoupling the three pillars of the application:

- **Presentation**: Lean SwiftUI Views observing @Observable ViewModels (@MainActor).
- **Navigation (The "+")**: Dedicated **Coordinators** managing the `NavigationPath` and sheet presentation logic.
- **Domain**: Protocol-oriented Services and SwiftData Repositories.

```text
ETPattern/
├── Models/           # SwiftData Entities (Card, CardSet, ReviewLog)
├── ViewModels/       # @Observable State Management
├── ViewControllers/  # Coordinators & Routers (Navigation Logic)
├── Services/         # I/O (TTSService, CloudSync, CSV)
├── Views/            # SwiftUI "Passive UI" Components
│   ├── Components/   # Reusable Bento Tiles & Glass Modifiers
│   └── Others/       # Settings, Onboarding, and Splash
├── Utilities/        # Theme Definitions & Metrics
└── Resources/        # Assets, Strings, and Bundled CSVs
```

---

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 18.0+ Device/Simulator
- Swift 6.0 Toolchain

### Deployment

**For primary testing (iPhone 16 Plus):**

```bash
./deploy.sh
```

---

## 📜 Changelog

### v2.3.0 - "Liquid & Grid" Refactor

- **Design System**: Implemented the **2026 Bento Grid system** for the Dashboard.
- **UX**:
  - Added **Global Auto Play** tile (One-tap session start).
  - Removed manual deck creation (Streamlined "Mastery-only" flow).
  - Hidden "Import" button to focus on core bundled content.
- **UI Architecture**:
  - Migrated to **MVVM+ with Coordinators** for decoupled navigation.
  - Standardized all titles to `theme.metrics.title2`.
  - Removed "System" theme option to ensure 100% visual consistency.
- **Fixes**: Resolved theme switching lag and layout wrapping regression in Settings.

### v2.2.0 - "The Brain Upgrade"

- **Algorithm**: Replaced SM-2 with **FSRS v4** (Stability/Difficulty tracking).
- **Cloud Sync**: Added robust configuration and sync status visibility.
- **UI**: Initial "Liquid Glass" refactor with `snap` haptics.

### v2.0.0 - "The Modern Era"

- **Persistence**: Migration to SwiftData + CloudKit.
- **UI**: Identity refresh with "Seamless Titanium" App Icon.

---

## 🔒 Privacy

English Thought is a privacy-first application. Your learning data is yours alone, living strictly on-device and in your private iCloud container.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

> **Happy Learning!** Master the patterns, master the language.
