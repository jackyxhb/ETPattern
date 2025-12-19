# English Thought v1.5.0 - English Pattern Flashcard App

## 🎉 Release Notes

**Release Date:** December 19, 2025
**Version:** 1.5.0
**Platform:** iOS 16.0+
**Device:** iPhone 16 and later

---

## ✨ What's New

### 🏗️ Code Architecture & UI Consolidation
- **Shared Components Library**: Created `SharedViews.swift` with reusable UI components including `SharedHeaderView`, `SharedCardDisplayView`, `SharedProgressBarView`, `SharedOrderToggleButton`, `SharedCloseButton`, and `CardFace` struct.
- **Card Display Unification**: Replaced `CardView` with `SharedCardDisplayView` in `DeckDetailView` for consistent theming and added interactive flip functionality with TTS support.
- **Comprehensive Theming**: Applied uniform theming to `AutoPlayView` and `StudyView` using shared components for seamless visual consistency.
- **Progress Enhancement**: Added percentage text display to progress bars across all views for improved user feedback.
- **Navigation Enhancement**: Added Onboarding button to header menu for quick access to introduction flow.

### 🔧 Technical Improvements
- **Code Deduplication**: Removed duplicate `CardView.swift` and consolidated card display logic into shared components.
- **Enum Resolution**: Fixed `SwipeDirection` enum conflicts by moving to global scope in `SharedViews.swift`.
- **Build Optimization**: Streamlined component architecture for better maintainability and performance.
- **Testing Verification**: Successfully built and tested on iPhone 16 Pro Max simulator with all features functional.

### 🎨 UI/UX Enhancements
- **Consistent Card Previews**: Deck detail view now shows interactive card previews with flip animation and audio playback.
- **Unified Progress Display**: All progress bars now show percentage completion for better learning progress tracking.
- **Improved Navigation**: Easy access to onboarding from header menu for new users.
- **Visual Consistency**: All views now share the same themed components for professional appearance.

---

## 📊 Statistics

- **Total Commits:** 40+ commits since initial release
- **Files Modified:** SharedViews.swift (new), DeckDetailView.swift, AutoPlayView.swift, StudyView.swift, CardView.swift (removed)
- **Code Improvements:** UI component consolidation, theming consistency, and architecture optimization
- **Testing:** Simulator verification on iPhone 16 Pro Max with successful builds

---

## 📋 System Requirements

- **iOS Version:** 16.0 or later
- **Xcode:** 15.0+
- **Swift:** 5.0+
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
- **Repository**: https://github.com/jackyxhb/ETPattern
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: Comprehensive README.md included

---

**Happy Learning with English Thought!** 📚✨

*Master 300+ English patterns through intelligent spaced repetition with enhanced, accessible UI.*