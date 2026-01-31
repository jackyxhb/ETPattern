# English Thought (ET) — Master 300 Expression Patterns 🧠

**English Thought (ET)** is a premium iOS spaced-repetition app designed to help learners internalize **300 core English expression patterns**. Built with SwiftUI and SwiftData, it treats language learning as a science, using an advanced FSRS algorithm to optimize review intervals within a state-of-the-art 2026 design language.

![iOS 18+](https://img.shields.io/badge/iOS-18.0+-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![Architecture](https://img.shields.io/badge/Arch-MVVM%2B-green.svg)
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)

---

## ✨ Key Features (v2.4)

### 🌎 Context-Aware Translation (AI Integration)

Native integration with the **iOS Translation API** (2025/2026 spec) for instant comprehension.

- **Dual-Face Translation**: English content on both the front and back of cards is automatically translated into the user's system language (Chinese).
- **Sentence-Level Precision**: The AI segments complex patterns into clear, understandable sentences for maximum learning efficiency.
- **Privacy First**: Translations happen via on-device machine learning, keeping your data private.

### 📐 Adaptive Study Architecture

A smart UI designed to handle the variable length of translations and extra context.

- **Internal Scrolling**: Cards now feature intelligent internal scrolling (`CardFace`), ensuring that long examples and translations never break the navigation or dashboard layout.
- **Dynamic Controls**: Control bars auto-adjust and "shrink-to-fit" based on the card state, keeping interaction buttons always within reach.
- **Pixel-Perfect Alignment**: Strict horizontal margin alignment (8pt) across **Study**, **Auto Play**, and **Deck Preview** modes.

### 🧠 Strategic Mastery Toggle

The primary learning interface now features a unified strategy cycling system.

- **Instant Switching**: Toggle between **Sequential**, **Random**, and **Intelligent (SRS)** ordering directly from the bottom control bar in all modes.
- **Animated Haptics**: Every strategy shift is accompanied by "snap" haptic feedback and fluid UI transitions.

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
├── Services/         # I/O (TTSService, CloudSync, Translation)
├── Views/            # SwiftUI "Passive UI" Components
│   ├── Components/   # Reusable Bento Tiles & CardFace Components
│   └── Others/       # Settings, Onboarding, and Splash
├── Utilities/        # Theme Definitions & Metrics
└── Resources/        # Assets, Strings, and Bundled CSVs
```

---

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 18.0+ Device/Simulator (Apple Silicon Mac for translation on simulator)
- Swift 6.0 Toolchain

### Deployment

**For primary testing (iPhone 16 Plus):**

```bash
./deploy.sh
```

---

## 📜 Changelog

### v2.4.0 - "The Context Update"

- **Translation Engine**:
  - Integrated **Apple Translation API** into `CardFace`.
  - Added support for multi-line translation on both card faces.
- **UI & Layout**:
  - Implemented **Internally Scrollable Cards** to handle long translations.
  - Aligned all card margins (8pt) across **Study**, **Auto Play**, and **DeckDetail**.
  - Refined **Header Logic**: Group names are now persistent on both sides of the card.
- **Features**:
  - Enabled **Strategy Cycling** (Sequential/Random/Intelligent) in StudyView.
  - Linked **UIImpactFeedback** to all primary control interactions.
- **Maintainability**:
  - Migrated all layout constants into the centralized `Theme` system.
  - Refactored `StudyView` and `LiquidCard` to use a unified `CardFace` component.

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
