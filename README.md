# English Thought (ET) — 300 Expression Patterns

English Thought (abbreviated **ET**) is a native SwiftUI iOS app that helps learners master **300 English expression patterns** through spaced repetition, full-screen cards, and natural text-to-speech audio. The bundled master deck is always named **ETPattern 300** to emphasize the complete pattern collection.

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)
![Xcode](https://img.shields.io/badge/Xcode-16+-red.svg)
![SPM](https://img.shields.io/badge/SPM-Supported-brightgreen.svg)
![Version](https://img.shields.io/badge/version-1.7.0-blue.svg)

## Highlights

**Learning Flow**
- Event-driven Auto Play keeps the flip animation and speech perfectly in sync — the card only advances when TTS finishes.
- Leitner-inspired spaced repetition powers swipe gestures (`Again` vs `Easy`) and keeps daily goals manageable.
- Full-screen, center-aligned typography with responsive flip animation for both manual and automatic review.
- **Card ID Display**: Every card now shows its unique ID number (e.g., "5/300") in the header for easy reference and navigation.

**Audio & TTS**
- AVSpeechSynthesizer wrapper (single shared instance) speaks every side as it becomes visible.
- American (en-US) and British (en-GB) voices with natural 0.48–0.52 rate and instant stop/resume support.

**Deck Management**
- Built-in **ETPattern 300** deck that aggregates the 12 bundled CSV groups (all 300 expression patterns).
- 12 bundled CSV decks (Groups 1–12) plus unlimited user imports following the `Front;;Back;;Tags` format.
- Long-press any deck to rename, delete, or re-import; per-deck progress persists between launches.
- **ID-based Ordering**: Cards in deck details are now sorted by their unique ID numbers for logical sequence navigation.

**Data Integrity**
- **Global Unique IDs**: Cards now have globally unique identifiers across all imported decks, preventing content duplication issues.
- **Migration Support**: Automatic data migration handles existing cards to ensure ID uniqueness.

**Experience**
- Gradient-rich interface, modern buttons, and progress components tuned for iPhone 16 displays.
- Linear progress bars, session stats, and Auto Play HUD keep learners focused without clutter.
- Onboarding guide for first-time users to get started quickly.
- Customizable settings for voice preferences, card ordering, and TTS options.

## Requirements

- iOS 16.0+ (optimized for iPhone 16 and later)
- Xcode 16+
- Swift 6.0+ (with modern concurrency features)
- iPhone 16 simulator or device recommended for optimal experience

## Project Structure

```
ETPattern/
├── ETPatternApp.swift        // App entry + DI
├── Persistence.swift         // Core Data stack + global unique ID assignment
├── Models/                   // Card, CardSet, StudySession entities
├── Services/                 // CSV, TTS, File, Spaced Repetition
├── Views/                    // ContentView, StudyView, AutoPlayView, SettingsView, OnboardingView, etc.
│   └── SharedViews.swift     // Shared UI components (SharedHeaderView, SharedCardDisplayView, etc.)
├── Utilities/                // Constants + Extensions + Theme
├── Resources/                // Group1–12 CSV bundles feeding the ETPattern 300 deck
└── Assets.xcassets           // Colors + icons
```

## Swift Package Manager

This project includes Swift Package Manager (SPM) support for modular development, testing, and dependency management.

### Package Structure

- `ETPatternCore`: Core data models and business logic (SPM-compatible)
- Test targets for unit testing core functionality

### Building with SPM

```bash
# Build the package
swift build

# Run tests
swift test

# Generate Xcode project from package
swift package generate-xcodeproj
```

### Adding External Dependencies

To add external dependencies, edit `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/example/package", from: "1.0.0"),
],
```

## Getting Started

Clone and open in Xcode:

```bash
git clone https://github.com/jackyxhb/ETPattern.git
cd ETPattern
open ETPattern.xcodeproj
```

### Quick Install & Run

Use the included install script for automatic device detection and installation:

```bash
./install.sh
```

The script automatically:
- Detects connected iOS devices (prioritizing physical devices over simulators)
- Builds the project for the selected device
- Installs and launches the app

### Manual Build Options

Build for simulator:

```bash
xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -sdk iphonesimulator -configuration Debug build
```

Install/run on a specific simulator:

```bash
# Replace DEVICE_ID with the simulator identifier from `xcrun simctl list`
xcrun simctl install DEVICE_ID build/Build/Products/Debug-iphonesimulator/ETPattern.app
xcrun simctl launch DEVICE_ID com.jack.ETPattern
```

## CSV Format

ETPattern consumes “chunk” CSVs using `;;` separators and `<br>` line breaks for examples.

```csv
Front;;Back;;Tags
I think...;;I think we should leave soon.<br>I think this is perfect.<br>I think you're right.<br>I think we can make it.<br>I think it’s solved.;;Opinions
```

Guidelines:
- Column order must be `Front`, `Back`, `Tags` (Tags optional).
- Use `<br>` for the five example sentences; they render as multi-line SwiftUI text.
- Files must be UTF-8 encoded.

## Architecture Notes

- **Core Data** keeps Card ↔ CardSet relationships, intervals, ease factors, and session history with globally unique card IDs.
- **SpacedRepetitionService** updates `interval`, `nextReviewDate`, and `easeFactor` for `Again` vs `Easy` ratings.
- **TTSService** wraps `AVSpeechSynthesizer` with token-based cancellation so Auto Play and Study views never overlap audio.
- **CSVImporter** parses bundled/user CSVs, normalizes `<br>` newlines, and persists new Card objects atomically with unique ID assignment.
- **FileManagerService** surfaces the 12 bundled CSVs and user-selected documents.
- **Card ID System**: Each card has a globally unique ID displayed in headers (e.g., "5/300") for easy reference and navigation.
- **Data Migration**: Automatic migration ensures existing cards receive unique IDs and maintains data integrity.

## Release Notes

### v1.6.0 (Latest)
- **Global Unique Card IDs**: Implemented globally unique card identifiers across all imported decks to prevent content duplication issues.
- **Card ID Display**: Added card ID numbers in headers showing "ID/Total" format (e.g., "5/300") for easy reference and navigation.
- **ID-based Card Ordering**: Cards in deck details now sort by their unique ID numbers instead of alphabetically for logical sequence navigation.
- **Data Migration**: Automatic migration system handles existing cards to ensure ID uniqueness and data integrity.
- **Type Safety Improvements**: Resolved Int32/Int type conversion issues throughout the codebase for better reliability.

### v1.5.0
- **Code Consolidation**: Extracted shared UI components into `SharedViews.swift` including `SharedHeaderView`, `SharedCardDisplayView`, `SharedProgressBarView`, `SharedOrderToggleButton`, `SharedCloseButton`, and `CardFace` struct.
- **Enhanced Card Previews**: Replaced `CardView` with `SharedCardDisplayView` in `DeckDetailView` for consistent theming and added flip functionality with TTS support.
- **UI Consistency**: Applied comprehensive theming to `AutoPlayView` and `StudyView` using shared components for uniform appearance across all views.
- **Progress Indicators**: Added percentage text display to progress bars for better user feedback.
- **Navigation Improvements**: Added Onboarding button to header menu for easy access to introduction flow.
- **Code Cleanup**: Removed duplicate `CardView.swift` and resolved `SwipeDirection` enum conflicts by moving to global scope.
- **Build Verification**: Successfully tested on iPhone 16 Pro Max simulator with all new features functional.

### v1.4.0
- Enhanced UI theming with modern design system color tokens for improved accessibility and consistency.
- Updated neutral gradient to purple for better button visibility.
- Applied theme typography to hero header for consistent font styling.
- Converted header actions to a dropdown menu with 3-dot ellipsis icon.
- Replaced system Menu with custom Popover for full theme control over background and text colors.
- Fixed popover visibility issues with proper contrast using theme-based colors.

### v1.3.0
- Enhanced swipe animations: Added visual feedback with checkmark (✓) for "Easy" swipes and X (✗) for "Again" swipes
- Improved UI layout: Moved swipe instruction text from card area to bottom navbar for cleaner card display
- Smooth slide animations: Feedback overlays now slide in smoothly during swipe gestures
- Device testing: Verified functionality on real iPhone 16 Plus device

### v1.2.0
- Optimized deck list display: Card counts now prefixed to deck names (e.g., "(36)ETPatterns 300") and voice indicators removed to maximize screen space for more items.
- Improved UI efficiency for better user experience on smaller screens.

### v1.1.0
- Auto Play now relies on event-driven speech completion, eliminating drift between audio and flip animations.
- Modernized study and Auto Play layouts with gradient backgrounds, refreshed buttons, and progress HUD polish.
- Reliability improvements for install/build automation (`xcodebuild` + `simctl`) and card-order persistence.

### v1.0.0
- Initial release with 12 bundled decks, Leitner-based study flow, CSV import, and configurable voice options.

## Contributing

1. Fork and create a feature branch.
2. Run `xcodebuild` + tests before opening a PR.
3. Describe UX changes with screenshots or short clips when possible.

## Branding Assets

- `Branding/logo.jpg` — primary English Thought mark (JPG image).
- `Branding/README.md` — palette, spacing, and export guidance for adapting the logo to app icons or marketing.

## License

MIT — see [LICENSE](LICENSE).

---

**Happy learning!** Master English patterns one immersive card at a time.