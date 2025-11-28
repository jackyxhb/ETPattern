# ETPattern - English Pattern Flashcard App

A beautiful, native iOS flashcard application designed to help users master 300+ English patterns through spaced repetition learning with automatic text-to-speech audio.

![iOS](https://img.shields.io/badge/iOS-26.1+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)
![Xcode](https://img.shields.io/badge/Xcode-15+-red.svg)

## ✨ Features

### 🎯 Core Learning Features
- **Spaced Repetition**: Intelligent algorithm that optimizes review timing based on your performance
- **300+ English Patterns**: Comprehensive collection covering opinions, suggestions, agreements, and more
- **Automatic TTS Audio**: Natural voice synthesis speaks each card aloud (American/British English options)
- **Interactive Card Flipping**: Smooth 180° rotation animation with tap-to-flip functionality

### 📚 Card Management
- **12 Built-in Groups**: Pre-loaded decks covering different pattern categories
- **CSV Import**: Import custom flashcard decks using the standard format
- **Deck Organization**: Create, rename, and manage multiple card sets
- **Progress Tracking**: Visual progress indicators and daily card counters

### 🎨 User Experience
- **Full-Screen Cards**: Large, centered text for optimal readability
- **Swipe Gestures**: Intuitive left/right swipes for "Again" and "Easy" responses
- **Session Statistics**: Track your learning progress over time
- **Voice Selection**: Choose between American and British English voices

## 📋 Requirements

- **iOS**: 26.1+
- **Xcode**: 15.0+
- **Swift**: 5.0+
- **Device**: iPhone 16 or later (optimized for iPhone 16)

## 🚀 Installation

### From Source
1. Clone the repository:
   ```bash
   git clone https://github.com/jackyxhb/ETPattern.git
   cd ETPattern
   ```

2. Open the project in Xcode:
   ```bash
   open ETPattern.xcodeproj
   ```

3. Select your target device (iPhone 16 recommended) and build:
   ```bash
   xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -sdk iphonesimulator -configuration Debug build
   ```

4. Run the app on simulator or device.

## 📖 Usage

### Getting Started
1. **Launch the App**: Open ETPattern on your iPhone 16
2. **Choose a Deck**: Select from 12 pre-loaded groups or import your own CSV
3. **Start Learning**: Tap "Play" to begin a spaced repetition session

### Study Session
- **Card Display**: Each card shows an English pattern on the front
- **Flip Cards**: Tap anywhere to reveal 5 example sentences on the back
- **Audio Playback**: Text is automatically spoken aloud when cards appear
- **Rate Your Knowledge**:
  - Swipe right: "Easy" - Card reviewed successfully
  - Swipe left or tap "Again": Review this card sooner

### Managing Decks
- **Long-press** any deck in the main list to:
  - Rename the deck
  - Delete the deck
  - Re-import CSV data

### Settings
- **Voice Selection**: Choose between American (en-US) and British (en-GB) English
- **Audio Settings**: TTS rate optimized for natural speech (0.48-0.52)

## 📄 CSV Format

Import your own flashcard decks using this exact format:

```csv
Front;;Back;;Tags
Pattern 1;;Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5;;Category
Pattern 2;;Example 1<br>Example 2<br>Example 3<br>Example 4<br>Example 5;;Category
```

**Format Rules:**
- **Separator**: Use `;;` (double semicolon) between columns
- **Line Breaks**: Use `<br>` to separate multiple examples in the Back column
- **Columns**: Front (pattern), Back (examples), Tags (optional category)
- **Encoding**: UTF-8

### Example:
```csv
Front;;Back;;Tags
I think...;;I think we should leave in about ten minutes.<br>I think this is the best coffee I've ever had.<br>I think you're going to love the surprise.<br>I think everyone needs at least eight hours of sleep.<br>I think it's going to rain later.;;1-Opinions
```

## 🏗️ Architecture

### Core Data Models
- **CardSet**: Manages collections of flashcards
- **Card**: Individual flashcard with front/back content and learning metadata
- **StudySession**: Tracks learning progress and statistics

### Key Services
- **CSVImporter**: Parses CSV files with custom ;; separator
- **TTSService**: Manages AVSpeechSynthesizer for audio playback
- **SpacedRepetitionService**: Implements Leitner system algorithm
- **FileManagerService**: Handles bundled and imported CSV files

### Views
- **ContentView**: Main deck selection interface
- **CardView**: Full-screen card display with flip animation
- **StudyView**: Interactive learning session with swipe gestures
- **SettingsView**: Voice selection and app preferences

## 🧪 Testing

The project includes comprehensive test suites:

### Unit Tests (`ETPatternTests/`)
- **CSVImporterTests**: Validates CSV parsing logic
- **SpacedRepetitionTests**: Tests learning algorithm accuracy

### UI Tests (`ETPatternUITests/`)
- **CardFlipTests**: Verifies card interaction animations
- **StudySessionTests**: Tests complete learning flow

Run tests with:
```bash
xcodebuild test -project ETPattern.xcodeproj -scheme ETPattern
```

## 📊 Learning Algorithm

The app uses a simplified spaced repetition system inspired by the Leitner method:

- **Easy Rating**: Increases interval by 1.5x current ease factor
- **Again Rating**: Resets interval to 1 day, slightly decreases ease factor
- **Smart Scheduling**: Cards appear when due for optimal retention

## 🔧 Development

### Project Structure
```
ETPattern/
├── Models/                 # Core Data entities
├── Views/                  # SwiftUI view components
├── Services/              # Business logic services
├── Utilities/             # Helper extensions and constants
├── Resources/             # CSV data files and assets
└── Tests/                 # Unit and UI test suites
```

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Local data persistence
- **AVFoundation**: Text-to-speech synthesis
- **Combine**: Reactive programming for state management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with SwiftUI and Core Data
- Spaced repetition algorithm inspired by proven learning techniques
- TTS powered by AVSpeechSynthesizer
- Designed specifically for iPhone 16 and iOS 26.1+

---

**Happy Learning!** 📚✨

*Master English patterns one card at a time with ETPattern.*