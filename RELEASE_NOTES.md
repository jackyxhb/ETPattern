# English Thought v2.0.6 - English Pattern Flashcard App

## 🎉 Release Notes

**Release Date:** January 12, 2026
**Version:** 2.0.6
**Platform:** iOS 17.0+
**Device:** iPhone 16 and later

---

## ✨ What's New

### What's New (v2.0.6)

### 🛠 Build Stability

- **CI/CD Fix**: Temporarily disabled automated version syncing during archives to resolve build stability issues in cloud environments.
- **Fixes**: General stability improvements.

### What's New (v2.0.5)

### 🤖 Automation

### What's New (v2.0.4)

### 💎 Branding & UI

- **Refined App Icon**: Finalized the "Seamless Titanium" icon with a 4x heaviness for better visibility and a premium industrial feel.

### 🛡️ Data & Stability

- **CSV Data Fix**: Resolved an issue where pattern data could be corrupted or redundant during import.
- **CI/CD**: Improved version synchronization in CI scripts to match git tags automatically.
- **Form Fixes**: Resolved iOS 17 `onChange` deprecation warnings in the UI.

### What's New (v2.0.0)

**The Modernization Update**
This major release overhauls the entire application architecture, UI, and learning engine.

### 🏛️ Modular Architecture

- **3-Tier Design**: Codebase refactored into `Models`, `Core` (Logic), and `Services` packages.
- **SwiftData**: Complete migration from Core Data to SwiftData for thread-safe, modern persistence.

### 💎 "Liquid Glass" Design

- **New Aesthetic**: Full UI redesign featuring glassmorphism, depth, and semantic colors.
- **Monogram Icon**: New App Icon featuring the "Liquid Glass" visual identity.

### 🧠 Intelligent SRS

- **4-Level Grading**: Upgraded from binary to "Againe, Hard, Good, Easy" ratings.
- **SM-2 Algorithm**: Industry-standard algorithm for optimized review intervals.
- **Smart Queue**: Prioritizes overdue cards to maximize learning efficiency.

### 🛡️ Data Resilience

- **Auto-Repair**: Automatically detects and fixes duplicate data on launch.
- **Ghost Filter**: Smart CSV import logic filters out malformed or blank lines.
- **Race Condition Fix**: Serialized initialization prevents double-import bugs.

---

### What's New (v1.8.0)

### 🔁 Sync & Stability

- Fixed intermittent audio overlap in Auto Play and improved quick-deck switching reliability.

### 🈶 Chinese Translations

- Added Chinese translations for each pattern and its five example sentences using the native Apple translation framework. Translations are fetched on demand, cached locally for offline access, and can be toggled on or off in the app settings.

### 🧩 Import & Parsing

- CSV importer now trims whitespace, tolerates minor tag formatting, and recovers gracefully from small malformed rows.

### ⚙️ Installer & CI

- `install.sh` improved for newer macOS releases; CI scripts updated for faster simulator selection.

### ♿ Accessibility & Localization

- Enhanced VoiceOver labels and improved localized strings in `es.lproj` and `en.lproj`.

### 🚀 Performance & Fixes

- Reduced main-thread work during deck load; several crash fixes and UI responsiveness improvements.

---

## Previous Release — v1.7.0

### 🆔 Global Unique Card IDs

- **Unique Identifier System**: Implemented globally unique card identifiers across all imported decks to prevent content duplication issues.
- **ID Display**: Added card ID numbers in headers showing "ID/Total" format (e.g., "5/300") for easy reference and navigation.
- **ID-based Ordering**: Cards in deck details now sort by their unique ID numbers instead of alphabetically for logical sequence navigation.

### 🔧 Data Integrity & Migration

- **Automatic Migration**: System automatically handles existing cards to ensure ID uniqueness and data integrity.
- **Type Safety**: Resolved Int32/Int type conversion issues throughout the codebase for better reliability.
- **Core Data Enhancement**: Updated Persistence layer to assign globally unique IDs during data seeding.

### 🎨 UI Improvements

- **Card Navigation**: Improved card ordering in DeckDetailView for better user experience.
- **Header Information**: Card headers now display unique identifiers for easy reference.
- **Consistent Display**: All views show card IDs uniformly across the application.

---

## 📊 Statistics

- **Total Commits:** 45+ commits since initial release
- **Files Modified:** Persistence.swift, DeckDetailView.swift, SharedViews.swift, SettingsView.swift, README.md
- **Code Improvements:** Data integrity, UI consistency, and navigation enhancements
- **Testing:** Simulator verification on iPhone 16 Pro Max with successful builds

---

## 📋 System Requirements

- **iOS Version:** 16.0 or later
- **Xcode:** 16.0+
- **Swift:** 6.0+
- **Device:** iPhone 16 or later (optimized for iPhone 16)
- **Storage:** ~50MB for app + bundled CSV data

---

## 🚀 Installation

### From Source

```bash
git clone https://github.com/jackyxhb/ETPattern.git
cd ETPattern
open ETPattern.xcodeproj
# Build and run in Xcode
```

### Simulator Testing

```bash
xcodebuild -scheme ETPattern -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build
xcrun simctl install booted /path/to/ETPattern.app
xcrun simctl launch booted com.jack.ETPattern
```

### Device Installation

```bash
# Build for device
xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -destination "id=YOUR_DEVICE_ID" build

# Install using ios-deploy
ios-deploy --bundle /path/to/ETPattern.app --id YOUR_DEVICE_ID
```

---

## 📖 Usage Guide

1. **Launch App**: Open English Thought on your iPhone
2. **Select Deck**: Choose from 12 pre-loaded groups or import custom CSV - card counts shown in parentheses
3. **Configure Settings**: Set voice preference and card ordering mode
4. **Start Learning**: Tap "Play" to begin spaced repetition session
5. **Study Flow**:
   - Tap cards to flip between pattern and examples
   - Listen to automatic TTS audio
   - **Swipe right for "Easy"** (✓ appears with slide animation)
   - **Swipe left for "Again"** (✗ appears with slide animation)
   - Monitor progress with linear progress bar showing percentage
   - Swipe instructions now visible in bottom navbar
6. **Header Menu**: Tap the 3-dot icon in the top-right for Session Stats, Import, Settings, and Onboarding with themed popover
7. **Card Previews**: Tap card previews in deck details to flip and hear TTS audio

---

## 🔄 Migration Notes

- **From v1.4.0**: All changes are backward compatible
- **UI Components**: Shared components ensure consistent theming across all views
- **Card Previews**: Deck detail view now includes interactive card previews
- **Navigation**: Onboarding now accessible from header menu
- **Progress Display**: All progress bars now show percentage completion

---

## 🙏 Acknowledgments

- **Development**: Jack Xiao - UI theming, modern design system, and accessibility improvements
- **Testing**: Comprehensive unit and UI test suites plus simulator testing
- **CI/CD**: GitHub Actions for automated quality assurance
- **Design**: Enhanced user experience with consistent theming and modern UI patterns

---

## 📞 Support

For issues, feature requests, or questions:

- **Repository**: <https://github.com/jackyxhb/ETPattern>
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: Comprehensive README.md included

---

**Happy Learning with English Thought!** 📚✨

*Master 300+ English patterns through intelligent spaced repetition with enhanced, accessible UI.*
