# English Thought (ET) — 300 Expression Patterns

English Thought (abbreviated **ET**) is a native SwiftUI iOS app that helps learners master **300 English expression patterns** through spaced repetition, full-screen cards, and natural text-to-speech audio. The bundled master deck is always named **ETPattern 300** to emphasize the complete pattern collection.

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-green.svg)
![Xcode](https://img.shields.io/badge/Xcode-15+-red.svg)

## Highlights

**Learning Flow**
- Event-driven Auto Play keeps the flip animation and speech perfectly in sync — the card only advances when TTS finishes.
- Leitner-inspired spaced repetition powers swipe gestures (`Again` vs `Easy`) and keeps daily goals manageable.
- Full-screen, center-aligned typography with responsive flip animation for both manual and automatic review.

**Audio & TTS**
- AVSpeechSynthesizer wrapper (single shared instance) speaks every side as it becomes visible.
- American (en-US) and British (en-GB) voices with natural 0.48–0.52 rate and instant stop/resume support.

**Deck Management**
- Built-in **ETPattern 300** deck that aggregates the 12 bundled CSV groups (all 300 expression patterns).
- 12 bundled CSV decks (Groups 1–12) plus unlimited user imports following the `Front;;Back;;Tags` format.
- Long-press any deck to rename, delete, or re-import; per-deck progress persists between launches.

**Experience**
- Gradient-rich interface, modern buttons, and progress components tuned for iPhone 16 displays.
- Linear progress bars, session stats, and Auto Play HUD keep learners focused without clutter.

## Requirements

- iOS 16.0+ (runs great on iOS 18 simulators)
- Xcode 15+
- Swift 5+
- iPhone 16 simulator or device recommended for previews

## Project Structure

```
ETPattern/
├── ETPatternApp.swift        // App entry + DI
├── Persistence.swift         // Core Data stack
├── Models/                   // Card, CardSet, StudySession entities
├── Services/                 // CSV, TTS, File, Spaced Repetition
├── Views/                    // ContentView, StudyView, AutoPlayView, etc.
├── Utilities/                // Constants + Extensions
├── Resources/                // Group1–12 CSV bundles feeding the ETPattern 300 deck
├── Assets.xcassets           // Colors + icons
├── Tests/                    // Unit tests
└── UITests/                  // UI automation
```

## Getting Started

Clone and open in Xcode:

```bash
git clone https://github.com/jackyxhb/ETPattern.git
cd ETPattern
open ETPattern.xcodeproj
```

Build (simulator example):

```bash
xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -sdk iphonesimulator -configuration Debug build
```

Install/run on a specific simulator:

```bash
# Replace DEVICE_ID with the simulator identifier from `xcrun simctl list`
xcrun simctl install DEVICE_ID build/Build/Products/Debug-iphonesimulator/ETPattern.app
xcrun simctl launch DEVICE_ID aaaa.ETPattern
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

- **Core Data** keeps Card ↔ CardSet relationships, intervals, ease factors, and session history.
- **SpacedRepetitionService** updates `interval`, `nextReviewDate`, and `easeFactor` for `Again` vs `Easy` ratings.
- **TTSService** wraps `AVSpeechSynthesizer` with token-based cancellation so Auto Play and Study views never overlap audio.
- **CSVImporter** parses bundled/user CSVs, normalizes `<br>` newlines, and persists new Card objects atomically.
- **FileManagerService** surfaces the 12 bundled CSVs and user-selected documents.

## Testing

| Suite | Location | Focus |
| --- | --- | --- |
| Unit | `ETPatternTests/CSVImporterTests.swift` | CSV parsing & data integrity |
| Unit | `ETPatternTests/SpacedRepetitionTests.swift` | Leitner math & scheduling |
| UI   | `ETPatternUITests/CardFlipTests.swift` | Flip animation and gestures |
| UI   | `ETPatternUITests/StudySessionTests.swift` | End-to-end review flow |

Run everything:

```bash
xcodebuild test -project ETPattern.xcodeproj -scheme ETPattern
```

## Release Notes

### v1.1.0 (Latest)
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

- `Branding/ETLogo.svg` — primary English Thought mark (speech/thought bubble with ET monogram).
- `Branding/README.md` — palette, spacing, and export guidance for adapting the logo to app icons or marketing.

## License

MIT — see [LICENSE](LICENSE).

---

**Happy learning!** Master English patterns one immersive card at a time.