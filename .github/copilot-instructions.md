# Copilot Instructions — ETPattern (English Thought)

SwiftUI iOS app (iOS 16+) for studying English pattern flashcards with Core Data persistence, CSV import/export, and automatic TTS.

## Big picture (where to look)
- App entry + DI: [ETPattern/ETPatternApp.swift](ETPattern/ETPatternApp.swift) injects Core Data `viewContext` + shared `TTSService` (`.environmentObject`). Initializes default UserDefaults in `init()`. Splash in [ETPattern/Views/SplashView.swift](ETPattern/Views/SplashView.swift), then [ETPattern/ContentView.swift](ETPattern/ContentView.swift) shows onboarding for new users.
- Persistence + seeding: [ETPattern/Persistence.swift](ETPattern/Persistence.swift) loads Core Data model from bundle, seeds bundled decks post-store load.
- Core Data model (codegen): Entities in [ETPattern/ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents](ETPattern/ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents). `Card.swift`/`CardSet.swift`/`StudySession.swift` are empty; add behavior via extensions like [ETPattern/Models/CardExtensions.swift](ETPattern/Models/CardExtensions.swift).
- Shared UI components: [ETPattern/Views/SharedViews.swift](ETPattern/Views/SharedViews.swift) contains reusable components like `SharedHeaderView`, `SharedCardDisplayView`, `SharedProgressBarView`, `SharedOrderToggleButton`, `SharedCloseButton`, `CardFace`, and global `SwipeDirection` enum.

## Decks + bundled data
- Bundled CSVs: `Resources/Group1.csv` … `Group12.csv` (via [ETPattern/Services/FileManagerService.swift](ETPattern/Services/FileManagerService.swift)).
- Single bundled cardset: `Constants.Decks.bundledMasterName` = "ETPattern 300", aggregates all cards. Cards tagged with `groupId`/`groupName`.

## Decks + bundled data
- Bundled CSVs: `Resources/Group1.csv` … `Group12.csv` (via [ETPattern/Services/FileManagerService.swift](ETPattern/Services/FileManagerService.swift)).
- Single bundled cardset: `Constants.Decks.bundledMasterName` = "ETPattern 300", aggregates all cards. Cards tagged with `groupId`/`groupName`.

## CSV conventions (import/export must match)
- Format: `Front;;Back;;Tags` with `<br>` for line breaks.
- Parsing: [ETPattern/Services/CSVImporter.swift](ETPattern/Services/CSVImporter.swift) splits by `;;`, skips header, replaces `<br>` → `\n`, assigns `card.id` by line number.
- Tags: Optional grouping as `^\d+-...` → `groupId` + `groupName`.
- Export: Same separator, `\n` → `<br>` in [ETPattern/ContentView.swift](ETPattern/ContentView.swift).

## TTS (single speaker, no overlap)
- `TTSService` in [ETPattern/Services/TTSService.swift](ETPattern/Services/TTSService.swift) wraps one `AVSpeechSynthesizer`, stops previous before speaking.
- Preferences: `UserDefaults` `selectedVoice` (e.g., `en-US`/`en-GB`), `ttsPercentage` → rate via `Constants.TTS.percentageToRate`.
- Auto-play: Relies on `speak(_:completion:)` callback.

## Study vs Auto-Play flows
- Study: [ETPattern/Views/StudyView.swift](ETPattern/Views/StudyView.swift) — tap flips/speaks, swipe right="Easy", left="Again". Ordering: `UserDefaults` `cardOrderMode` (`random`/`sequential`). Scheduling: [ETPattern/Services/SpacedRepetitionService.swift](ETPattern/Services/SpacedRepetitionService.swift), `Card.recordReview`. Uses shared components from [ETPattern/Views/SharedViews.swift](ETPattern/Views/SharedViews.swift).
- Auto-play: [ETPattern/Views/AutoPlayView.swift](ETPattern/Views/AutoPlayView.swift) — event-driven, TTS completion advances phases. Cancellation: UUID `speechToken`. Progress: `UserDefaults` `autoPlayProgress-<CardSet.objectID.uriRepresentation()>`. Ordering: `autoPlayOrderMode`. Uses shared components for consistent theming.
- Deck details: [ETPattern/Views/DeckDetailView.swift](ETPattern/Views/DeckDetailView.swift) — shows card previews using `SharedCardDisplayView` with flip and TTS functionality.

## Deck management patterns
- Main list: [ETPattern/ContentView.swift](ETPattern/ContentView.swift) — context menu for Rename/Delete/Re-import/Export.
- Re-import: User files use security-scoped URLs; bundled reloads from `Resources/Group*.csv`.

## User experience flows
- Onboarding: First launch shows [ETPattern/Views/OnboardingView.swift](ETPattern/Views/OnboardingView.swift) with intro pages; completion stored in UserDefaults. Also accessible via header menu button.
- Settings: [ETPattern/Views/SettingsView.swift](ETPattern/Views/SettingsView.swift) for voice selection, card/auto-play order modes, TTS rate/pitch/volume/pause.

## Developer workflow
- Open `ETPattern.xcodeproj` in Xcode 15+.
- Build: `xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -sdk iphonesimulator -configuration Debug build`
- Install/run: `install.sh` selects device (USB iPhone > booted sim > boot iPhone 16 sim), resolves app path via `xcodebuild -showBuildSettings`.