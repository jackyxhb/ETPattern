# ETPattern v1.0.0 - English Pattern Flashcard App

## 🎉 Release Notes

**Release Date:** November 29, 2025  
**Version:** 1.0.0  
**Platform:** iOS 16.0+  
**Device:** iPhone 16 and later  

---

## ✨ What's New

### 🚀 Core Features
- **Complete Flashcard Learning System**: Full implementation of spaced repetition learning for 300+ English patterns
- **Automatic Text-to-Speech**: Natural voice synthesis with American/British English voice selection
- **CSV Import System**: Import custom flashcard decks with ;; separator and <br> line breaks
- **Interactive Card Flipping**: Smooth 180° rotation animations with tap-to-flip functionality
- **Swipe Gestures**: Intuitive left/right swipes for "Again" and "Easy" card ratings

### 🎯 Learning Features
- **Spaced Repetition Algorithm**: Intelligent review scheduling based on performance
- **12 Built-in Pattern Groups**: Pre-loaded comprehensive English pattern collections
- **Session Statistics**: Track learning progress with detailed metrics
- **Card Management**: Create, rename, and organize multiple flashcard decks

### 🎨 User Interface
- **Linear Progress Bar**: Clean horizontal progress indicator with percentage display
- **Configurable Card Ordering**: Choose between random order or sequential import order
- **Full-Screen Card Display**: Large, centered text for optimal readability
- **Context Menus**: Long-press deck management with rename, delete, and re-import options

### ⚙️ Settings & Customization
- **Voice Selection**: Switch between American (en-US) and British (en-GB) English
- **Card Order Preferences**: Random or sequential study modes
- **Persistent Settings**: All preferences saved across app sessions
- **Audio Optimization**: TTS rate tuned for natural speech (0.48-0.52)

---

## 🔧 Technical Improvements

### Architecture
- **SwiftUI Framework**: Modern declarative UI with iOS 16.0+ compatibility
- **Core Data Integration**: Robust data persistence with CardSet, Card, and StudySession entities
- **Service-Oriented Design**: Modular services for CSV import, TTS, and spaced repetition
- **MVVM Pattern**: Clean separation of concerns with observable objects

### Code Quality
- **Unit Tests**: Comprehensive test coverage for CSV import and spaced repetition logic
- **UI Tests**: Automated testing for card interactions and navigation flows
- **GitHub Actions CI/CD**: Automated Xcode builds and analysis
- **Code Generation**: Category-based Core Data model generation

### Performance
- **Optimized TTS**: Single synthesizer instance with proper speech interruption
- **Efficient Data Loading**: Smart card set initialization and session management
- **Memory Management**: Proper cleanup and resource management

---

## 🐛 Bug Fixes & Improvements

### Session Management
- Fixed card set initialization checks for reliable data loading
- Improved session handling with accurate progress tracking
- Enhanced card counter display logic
- Better handling of empty card sets and edge cases

### User Experience
- Replaced circular progress indicator with linear progress bar
- Added configurable card ordering with persistent settings
- Improved navigation with "Home" button for session completion
- Enhanced card display with index and total count

### Audio & TTS
- Added speech interruption on card changes
- Implemented voice selection persistence
- Optimized TTS rate for natural speech patterns

---

## 📊 Statistics

- **Total Commits:** 21 commits since initial release
- **Files Modified:** 25+ source files
- **Test Coverage:** Unit tests for core services, UI tests for interactions
- **CSV Files:** 12 pre-loaded pattern groups with 300+ cards
- **Supported Languages:** English (American & British variants)

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
xcodebuild -scheme ETPattern -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install booted /path/to/ETPattern.app
xcrun simctl launch booted aaaa.ETPattern
```

---

## 📖 Usage Guide

1. **Launch App**: Open ETPattern on your iPhone
2. **Select Deck**: Choose from 12 pre-loaded groups or import custom CSV
3. **Configure Settings**: Set voice preference and card ordering mode
4. **Start Learning**: Tap "Play" to begin spaced repetition session
5. **Study Flow**:
   - Tap cards to flip between pattern and examples
   - Listen to automatic TTS audio
   - Swipe right for "Easy", left for "Again"
   - Monitor progress with linear progress bar

---

## 🔄 Migration Notes

- **First Release**: No migration needed
- **Settings**: Default to American English voice and random card order
- **Data**: All 300 patterns loaded from bundled CSV files

---

## 🙏 Acknowledgments

- **Development**: Jack Xiao - Complete implementation and testing
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

**Happy Learning with ETPattern!** 📚✨

*Master 300+ English patterns through intelligent spaced repetition.*