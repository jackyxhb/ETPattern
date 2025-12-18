# English Thought v1.4.0 - English Pattern Flashcard App

## 🎉 Release Notes

**Release Date:** December 19, 2025
**Version:** 1.4.0
**Platform:** iOS 16.0+
**Device:** iPhone 16 and later

---

## ✨ What's New

### 🎨 Enhanced UI Theming & Accessibility
- **Modern Design System**: Implemented comprehensive color tokens (background, onBackground, surface, onSurface, surfaceElevated, onSurfaceElevated, outline) for consistent theming across the app.
- **Improved Gradient Visibility**: Updated neutral gradient to purple for better contrast and visibility of UI elements like buttons.
- **Theme Typography**: Applied consistent theme fonts to hero header and other text elements for better readability.
- **Custom Dropdown Menu**: Converted header actions to a 3-dot ellipsis icon with custom Popover for full theme control.
- **Popover Theming**: Replaced system Menu with custom Popover using theme-based colors for proper contrast and modern appearance.
- **Accessibility Fixes**: Ensured all UI elements meet contrast requirements with theme-compliant colors.

### 🔧 Technical Updates
- **Theme System Expansion**: Added modern design system color tokens to Theme.swift for semantic color usage.
- **UI Component Updates**: Modified ContentView.swift to use themed Popover with surfaceElevated background and onSurfaceElevated text.
- **Build Verification**: Tested and verified on iPhone 16 Pro Max simulator with successful builds.

---

## 📊 Statistics

- **Total Commits:** 35+ commits since initial release
- **Files Modified:** Theme.swift, ContentView.swift, and UI components
- **UI Improvements:** Theming, accessibility, and modern design system implementation
- **Testing:** Simulator verification on iPhone 16 Pro Max

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
   - Monitor progress with linear progress bar
   - Swipe instructions now visible in bottom navbar
6. **Header Menu**: Tap the 3-dot icon in the top-right for Session Stats, Import, and Settings with themed popover

---

## 🔄 Migration Notes

- **From v1.3.0**: UI changes are backward compatible
- **Theme Updates**: All colors now use modern design system tokens
- **Header Actions**: Now consolidated in themed dropdown menu
- **Settings**: All existing preferences preserved

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