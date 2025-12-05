# English Thought v1.2.0 - English Pattern Flashcard App

## 🎉 Release Notes

**Release Date:** December 4, 2025  
**Version:** 1.2.0  
**Platform:** iOS 16.0+  
**Device:** iPhone 16 and later  

---

## ✨ What's New

### 🎨 UI Optimization
- **Deck List Enhancement**: Card counts now displayed as prefixes to deck names (e.g., "(36)ETPattern 300") for immediate visibility
- **Space Efficiency**: Removed voice indicators from deck list items to maximize screen real estate
- **Improved Scrolling**: More deck items visible without scrolling on standard iPhone screens

### 🔧 Technical Updates
- **Build System**: Updated Xcode project for iOS 26.1 simulator compatibility
- **Asset Management**: Streamlined logo and icon generation from Branding/logo.jpg
- **Code Cleanup**: Removed unused UI components and optimized view rendering

---

## 📊 Statistics

- **Total Commits:** 23 commits since initial release
- **Files Modified:** 27+ source files
- **UI Improvements:** Deck list optimization for better usability
- **Build Compatibility:** iOS 26.1 simulator support added

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
xcodebuild -scheme ETPattern -destination 'platform=iOS Simulator,name=iPhone 16' build
xcrun simctl install booted /path/to/ETPattern.app
xcrun simctl launch booted aaaa.ETPattern
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
   - Swipe right for "Easy", left for "Again"
   - Monitor progress with linear progress bar

---

## 🔄 Migration Notes

- **From v1.1.0**: UI changes are backward compatible
- **Deck Display**: Card counts now appear as prefixes in deck names
- **Settings**: All existing preferences preserved

---

## 🙏 Acknowledgments

- **Development**: Jack Xiao - UI optimization and build improvements
- **Testing**: Comprehensive unit and UI test suites
- **CI/CD**: GitHub Actions for automated quality assurance
- **Design**: Optimized for iPhone 16 with modern SwiftUI patterns

---

## 📞 Support

For issues, feature requests, or questions:
- **Repository**: https://github.com/jackyxhb/ETPattern
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: Comprehensive README.md included

---

**Happy Learning with English Thought!** 📚✨

*Master 300+ English patterns through intelligent spaced repetition.*