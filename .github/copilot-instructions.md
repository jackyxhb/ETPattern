# Copilot Instructions — ETPattern (English Thought)

SwiftUI iOS app (iOS 16+) for studying English pattern flashcards with Core Data persistence, CSV import/export, and automatic TTS.

## Big picture (where to look)
- App entry + DI: [ETPattern/ETPatternApp.swift](../ETPattern/ETPatternApp.swift) injects Core Data `viewContext` + a single shared `TTSService` (`.environmentObject`). Splash wrapper is in [ETPattern/Views/SplashView.swift](../ETPattern/Views/SplashView.swift).
- Persistence + seeding: [ETPattern/Persistence.swift](../ETPattern/Persistence.swift) loads the Core Data model explicitly from the module bundle and seeds bundled decks after the store loads.
- Core Data model (codegen): entities live in [ETPattern/ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents](../ETPattern/ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents). `Card.swift`/`CardSet.swift`/`StudySession.swift` are intentionally empty because Xcode generates classes ("Class Definition"). Add computed behavior via extensions like [ETPattern/Models/CardExtensions.swift](../ETPattern/Models/CardExtensions.swift).

## Decks + bundled data
- Bundled CSVs are `Resources/Group1.csv` … `Group12.csv` (loaded via [ETPattern/Services/FileManagerService.swift](../ETPattern/Services/FileManagerService.swift)).
- Only one bundled cardset is created named `Constants.Decks.bundledMasterName` = "ETPattern 300" (legacy name "ETPatterns 300" is migrated on launch in `PersistenceController.seedBundledCardSets`), containing all cards from the 12 group CSVs. Cards are tagged with `groupId` and `groupName` for internal grouping within the deck.

## CSV conventions (import/export must match)
- Format is `Front;;Back;;Tags` with `<br>` in `Back` meaning line breaks.
- Parsing is in [ETPattern/Services/CSVImporter.swift](../ETPattern/Services/CSVImporter.swift):
  - Splits by `;;`, skips header, replaces `<br>` → `\n`, assigns `card.id` by (1-based) line number.
  - Tags optionally encode grouping as `^\d+-...` → `groupId` + `groupName`.
- Export uses the same separator and converts `\n` back to `<br>` in [ETPattern/ContentView.swift](../ETPattern/ContentView.swift).

## TTS (single speaker, no overlap)
- `TTSService` in [ETPattern/Services/TTSService.swift](../ETPattern/Services/TTSService.swift) wraps one `AVSpeechSynthesizer`, always stops previous speech before speaking.
- Voice preference is stored in `UserDefaults` key `selectedVoice` (may be language like `en-US`/`en-GB` or a concrete voice identifier); rate is stored as `ttsPercentage` and converted via `Constants.TTS.percentageToRate`.
- Auto-play relies on the `speak(_:completion:)` callback; keep it reliable when changing speech behavior.

## Study vs Auto-Play flows
- Study session UI: [ETPattern/Views/StudyView.swift](../ETPattern/Views/StudyView.swift)
  - Tap flips and speaks the visible side; swipe right = "Easy", swipe left = "Again".
  - Ordering uses `UserDefaults` key `cardOrderMode` (`random`/`sequential`).
  - Scheduling uses [ETPattern/Services/SpacedRepetitionService.swift](../ETPattern/Services/SpacedRepetitionService.swift) and per-card counters via `Card.recordReview`.
- Auto-play UI: [ETPattern/Views/AutoPlayView.swift](../ETPattern/Views/AutoPlayView.swift)
  - Event-driven: TTS completion advances phases (`front` → flip → `back` → next card).
  - Cancellation uses a UUID `speechToken`; progress is persisted per-deck in `UserDefaults` as `autoPlayProgress-<CardSet.objectID.uriRepresentation()>`.
  - Ordering uses `UserDefaults` key `autoPlayOrderMode`.

## Deck management patterns
- Main deck list is [ETPattern/ContentView.swift](../ETPattern/ContentView.swift): context menu for Rename/Delete/Re-import/Export.
- Re-import for user-picked files uses security-scoped URLs (`startAccessingSecurityScopedResource`). Bundled re-import bypasses picker and reloads from `Resources/Group*.csv`.

## Developer workflow
- Open `ETPattern.xcodeproj` in Xcode 15+. CLI build examples are in [README.md](../README.md).
- `install.sh` device selection policy: list devices via `devicectl` → first USB-connected physical iPhone (checks `transportType == "usb"`) → else first booted iPhone simulator → else boot an available “iPhone 16” simulator and target it. The app path is resolved via `xcodebuild -showBuildSettings` (no hard-coded DerivedData paths).