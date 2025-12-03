# GitHub Copilot Instructions – English Thought (ET) Flashcard iOS App
# Target: Swift + SwiftUI, iOS 16+, Xcode 15+
# Goal: Build **English Thought (ET)**, a beautiful native iOS app that imports your 12-group CSV files and helps learners master **300 English expression patterns** with auto-TTS audio. The bundled master deck is always called **“ETPattern 300”** to reflect those 300 patterns.

## Core Requirements (must be implemented exactly)
1. The app must import CSV files in this exact format (separator: ;;):
   Front;;Back;;Tags
   (Back contains 5 examples separated by <br>)

2. Each imported CSV becomes a CardSet (deck) named after the file or group.
3. One Card =
   - front: the pattern (e.g. "I think...")
   - back: 5 examples with <br> line breaks (HTML displayed as multi-line text)

4. Card display
   - Full-screen card with big, centred text
   - Tap anywhere → flip animation (180° rotation)
   - Front = bold pattern
   - Back = pattern at the top (smaller) + 5 examples below (nice line spacing)

5. Automatic TTS Audio
   - Every time a side becomes visible → speak its text aloud
   - Use AVSpeechSynthesizer (en-US or en-GB voice, natural rate 0.48–0.52)
   - One speaker instance only (stop previous utterance before new one)
   - Optional: let user choose American / British voice in Settings

6. Learning flow
   - "Play" button → starts spaced-repetition session (simple Leitner or basic daily review is enough)
   - Swipe right = "Easy/Know it" → longer interval
   - Swipe left or "Again" button = see again soon
   - Progress circle + cards today counter

7. CardSet management
    - List of decks (Group 1–12 + built-in **ETPattern 300** + any imported CSV)
   - Long-press → Rename / Delete / Re-import
   - Built-in 12 groups already included as bundled CSV assets

## Project Structure (create exactly these files)

### Core Data Models
- `Models/CardSet.swift` - NSManagedObject subclass for deck/cardset
- `Models/Card.swift` - NSManagedObject subclass for individual flashcards
- `Models/StudySession.swift` - NSManagedObject for tracking learning progress
- `ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents` - Core Data model file with entities:
  - CardSet: name, createdDate, cards relationship
  - Card: front, back, tags, difficulty, nextReviewDate, interval, easeFactor
  - StudySession: date, cardsReviewed, correctCount

### Views
- `Views/ContentView.swift` - Main deck list view
- `Views/CardView.swift` - Full-screen card display with flip animation
- `Views/StudyView.swift` - Learning session interface with swipe gestures
- `Views/DeckDetailView.swift` - Individual deck management
- `Views/SettingsView.swift` - TTS voice selection and app settings
- `Views/ImportView.swift` - CSV file import interface

### Services
- `Services/CSVImporter.swift` - Parse CSV files with ;; separator, handle <br> line breaks
- `Services/TTSService.swift` - AVSpeechSynthesizer wrapper with voice selection
- `Services/SpacedRepetitionService.swift` - Leitner system implementation
- `Services/FileManagerService.swift` - Handle bundled CSV assets and user imports

### Utilities
- `Utilities/Constants.swift` - App constants, TTS rates, voice identifiers
- `Utilities/Extensions.swift` - String extensions for HTML parsing, Date formatters

### Resources
- `Assets.xcassets/` - App icons, accent colors
- `Resources/Group1.csv` through `Resources/Group12.csv` - Bundled CSV files feeding the master deck named **ETPattern 300** (represents all 300 expression patterns)
- `Preview Content/Preview Assets.xcassets/` - Preview assets

### Main App Files
- `ETPatternApp.swift` - App entry point with dependency injection
- `Persistence.swift` - Core Data stack (updated for new entities)

### Tests
- `ETPatternTests/CSVImporterTests.swift` - Test CSV parsing logic
- `ETPatternTests/SpacedRepetitionTests.swift` - Test learning algorithm
- `ETPatternUITests/CardFlipTests.swift` - Test card interaction
- `ETPatternUITests/StudySessionTests.swift` - Test learning flow

## Implementation Guidelines

### CSV Import Logic
```swift
// In CSVImporter.swift
func parseCSV(_ content: String) -> [Card] {
    let lines = content.components(separatedBy: .newlines)
    return lines.dropFirst().compactMap { line in
        let components = line.components(separatedBy: ";;")
        guard components.count >= 2 else { return nil }
        let front = components[0]
        let back = components[1].replacingOccurrences(of: "<br>", with: "\n")
        let tags = components.count > 2 ? components[2] : ""
        return Card(front: front, back: back, tags: tags)
    }
}
```

### Card Flip Animation
```swift
// In CardView.swift
struct CardView: View {
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            CardFace(text: frontText, isFront: true)
                .opacity(isFlipped ? 0 : 1)
            CardFace(text: backText, isFront: false)
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture { withAnimation { isFlipped.toggle() } }
    }
}
```

### TTS Integration
```swift
// In TTSService.swift
class TTSService {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, voice: String = "en-US") {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: voice)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
```

### Spaced Repetition Algorithm
```swift
// In SpacedRepetitionService.swift
func updateCardDifficulty(_ card: Card, rating: DifficultyRating) {
    switch rating {
    case .again:
        card.interval = 1
        card.easeFactor = max(1.3, card.easeFactor - 0.2)
    case .easy:
        card.interval = Int(Double(card.interval) * card.easeFactor * 1.5)
        card.easeFactor = min(2.5, card.easeFactor + 0.1)
    }
    card.nextReviewDate = Date().addingTimeInterval(TimeInterval(card.interval * 86400))
}
```

## Key Integration Points
- Use `FileManager` to access bundled CSV files from `Bundle.main`
- Implement `UIViewRepresentable` for custom card flip animations if needed
- Use `AVSpeechSynthesizerDelegate` for TTS state management
- Store user preferences in `UserDefaults` for voice selection
- Use Core Data relationships to link cards to cardsets efficiently