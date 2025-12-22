# ETPattern Project Instructions

This is the unified guide for AI agents working on the ETPattern iOS app. It consolidates project overview, standards, architecture, and global guidelines into one reference.

## Section 1: Project Overview

SwiftUI iOS app (iOS 16+) for studying English pattern flashcards with Core Data persistence, CSV import/export, and automatic TTS.

### Big picture (where to look)
- App entry + DI: [ETPattern/ETPatternApp.swift](ETPattern/ETPatternApp.swift) injects Core Data `viewContext` + shared `TTSService` (`.environmentObject`). Initializes default UserDefaults in `init()`. Splash in [ETPattern/Views/SplashView.swift](ETPattern/Views/SplashView.swift), then [ETPattern/ContentView.swift](ETPattern/ContentView.swift) shows onboarding for new users.
- Persistence + seeding: [ETPattern/Persistence.swift](ETPattern/Persistence.swift) loads Core Data model from bundle, seeds bundled decks post-store load.
- Core Data model (codegen): Entities in [ETPattern/ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents](ETPattern/ETPattern.xcdatamodeld/ETPattern.xcdatamodel/contents). `Card.swift`/`CardSet.swift`/`StudySession.swift` are empty; add behavior via extensions like [ETPattern/Models/CardExtensions.swift](ETPattern/Models/CardExtensions.swift).
- Shared UI components: [ETPattern/Views/SharedViews.swift](ETPattern/Views/SharedViews.swift) contains reusable components like `SharedHeaderView`, `SharedCardDisplayView`, `SharedProgressBarView`, `SharedOrderToggleButton`, `SharedCloseButton`, `CardFace`, and global `SwipeDirection` enum.

### Decks + bundled data
- Bundled CSVs: `Resources/Group1.csv` … `Group12.csv` (via [ETPattern/Services/FileManagerService.swift](ETPattern/Services/FileManagerService.swift)).
- Single bundled cardset: `Constants.Decks.bundledMasterName` = "ETPattern 300", aggregates all cards. Cards tagged with `groupId`/`groupName`.

### CSV conventions (import/export must match)
- Format: `Front;;Back;;Tags` with `<br>` for line breaks.
- Parsing: [ETPattern/Services/CSVImporter.swift](ETPattern/Services/CSVImporter.swift) splits by `;;`, skips header, replaces `<br>` → `\n`, assigns `card.id` by line number.
- Tags: Optional grouping as `^\d+-...` → `groupId` + `groupName`.
- Export: Same separator, `\n` → `<br>` in [ETPattern/ContentView.swift](ETPattern/ContentView.swift).

### TTS (single speaker, no overlap)
- `TTSService` in [ETPattern/Services/TTSService.swift](ETPattern/Services/TTSService.swift) wraps one `AVSpeechSynthesizer`, stops previous before speaking.
- Preferences: `UserDefaults` `selectedVoice` (e.g., `en-US`/`en-GB`), `ttsPercentage` → rate via `Constants.TTS.percentageToRate`.
- Auto-play: Relies on `speak(_:completion:)` callback.

### Study vs Auto-Play flows
- Study: [ETPattern/Views/StudyView.swift](ETPattern/Views/StudyView.swift) — tap flips/speaks, swipe right="Easy", left="Again". Ordering: `UserDefaults` `cardOrderMode` (`random`/`sequential`). Scheduling: [ETPattern/Services/SpacedRepetitionService.swift](ETPattern/Services/SpacedRepetitionService.swift), `Card.recordReview`. Uses shared components from [ETPattern/Views/SharedViews.swift](ETPattern/Views/SharedViews.swift).
- Auto-play: [ETPattern/Views/AutoPlayView.swift](ETPattern/Views/AutoPlayView.swift) — event-driven, TTS completion advances phases. Cancellation: UUID `speechToken`. Progress: `UserDefaults` `autoPlayProgress-<CardSet.objectID.uriRepresentation()>`. Ordering: `autoPlayOrderMode`. Uses shared components for consistent theming.
- Deck details: [ETPattern/Views/DeckDetailView.swift](ETPattern/Views/DeckDetailView.swift) — shows card previews using `SharedCardDisplayView` with flip and TTS functionality.

### Deck management patterns
- Main list: [ETPattern/ContentView.swift](ETPattern/ContentView.swift) — context menu for Rename/Delete/Re-import/Export.
- Re-import: User files use security-scoped URLs; bundled reloads from `Resources/Group*.csv`.

### User experience flows
- Onboarding: First launch shows [ETPattern/Views/OnboardingView.swift](ETPattern/Views/OnboardingView.swift) with intro pages; completion stored in UserDefaults. Also accessible via header menu button.
- Settings: [ETPattern/Views/SettingsView.swift](ETPattern/Views/SettingsView.swift) for voice selection, card/auto-play order modes, TTS rate/pitch/volume/pause.

### Developer workflow
- Open `ETPattern.xcodeproj` in Xcode 15+.
- Build: `xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -sdk iphonesimulator -configuration Debug build`
- Install/run: `install.sh` selects device (USB iPhone > booted sim > boot iPhone 16 sim), resolves app path via `xcodebuild -showBuildSettings`.

## Section 2: AI Agent Standards

You are an Expert iOS Developer tasked with refactoring and expanding the ETPattern app. Your goal is to move the project from "Functional Prototype" to "Production Grade" by strictly following the instructions below.

### 1. Architectural Mandates (MVVM+)
- **Decouple Core Data:** ViewModels must not access `NSManagedObjectContext` directly. Create a `DataRepository` layer to handle CRUD operations.
- **Modern Navigation:** Replace all `NavigationView` implementations with `NavigationStack` or `NavigationPath` (iOS 16+).
- **Dependency Injection:** Services (like `TTSService`) must be injected into ViewModels via initializers to facilitate testing.
- **State Management:** Use a unified `ViewState` enum (`idle`, `loading`, `success`, `error`) to drive UI updates.

### 2. Threading & Performance
- **Non-Blocking UI:** All Core Data saving and heavy fetching must occur on a background context using `performBackgroundTask`.
- **Memory Safety:** Every Combine pipeline (`sink`, `assign`) or escaping closure must use `[weak self]` to prevent memory leaks.
- **Efficient Fetching:** Avoid fetching entire datasets. Use `fetchLimit`, `fetchOffset`, and `@FetchRequest` predicates to minimize memory footprint.

### 3. Code Quality & Safety
- **Unit Testing First:** Every new ViewModel or Service must have a corresponding XCTest file. Aim for 80% coverage on logic.
- **No Hard-coding:** All strings must use `NSLocalizedString`. All dimensions and colors must use the `Theme` utility.
- **Swift Concurrency:** Favor `async/await` and `Task` over `DispatchQueue.main.asyncAfter` for asynchronous flows.
- **Error Propagation:** Replace generic `alerts` with a unified `AppError` type that provides specific recovery suggestions.

### 4. UI/UX & Accessibility
- **Adaptive Layouts:** Do not use hard-coded font sizes (e.g., `.font(.system(size: 20))`). Use semantic styles (e.g., `.font(.title2)`) to support **Dynamic Type**.
- **Visual Feedback:** Every asynchronous action must provide a `ProgressView` or shimmer effect during execution.
- **Platform Alignment:** Follow Human Interface Guidelines (HIG) for sheets, modals, and haptic feedback.

### 5. Security & Persistence
- **Sensitive Data:** Move any user credentials or sensitive tokens from `UserDefaults` to the **Keychain**.
- **Data Integrity:** Ensure `NSPersistentContainer` is configured to handle schema migrations safely.

### Execution Workflow for the Agent
1. **Analyze:** Identify which of the improvement areas apply to the current task.
2. **Draft:** Propose interface changes (Protocols/Models) before implementing UI.
3. **Refactor:** Clean up existing technical debt (e.g., removing `NavigationView`) while adding new code.
4. **Verify:** Confirm new code includes `[weak self]` and is covered by a Unit Test stub.

## Section 3: MVVM Architecture

You are a Senior iOS Architect specializing in **MVVM (Model-View-ViewModel)**. Your goal is to guide the development of a modular, testable, and scalable iOS application using Swift.

### Core Architectural Principles
You must adhere to the following strict separation of concerns:

#### 1. The Model (Data Layer)
- **Role:** Represent data structures and business logic.
- **Constraints:** Must be agnostic of the UI. Use `Codable` for API responses and `Protocols` for data repositories.
- **Implementation:** Define raw data types (Structs) and Services (Networking/Persistence). For ETPattern, integrate Core Data entities (e.g., `Card`, `CardSet`) with extensions for logic, and use `DataRepository` protocols for abstraction.

#### 2. The ViewModel (Logic Layer)
- **Role:** Act as the "Source of Truth" for the View. Transform Model data into UI-ready values.
- **Constraints:** Strictly No `import UIKit` or `import SwiftUI` (unless using specialized types like `LocalizedStringKey`).
- Must use **Observable Objects** (`@Published` in SwiftUI or Combine/Closures in UIKit) to notify the View of changes.
- Must handle all formatting (e.g., date formatting, currency strings).
- **Dependency Injection:** Services must be injected via the initializer to allow for Mocking.

#### 3. The View (UI Layer)
- **Role:** Declarative representation of the UI.
- **Constraints:** Must be "Passive." No business logic or data fetching allowed within the View.
- Should only observe the ViewModel and forward user intents (e.g., button taps) to ViewModel methods.

### Workflow Instructions for the Agent
When asked to build a feature, follow these steps in order:

1. **Define the Data Model:** Start by creating the `Struct` and any necessary API/Service protocols.
2. **Draft the ViewModel:** Define an `enum State` (e.g., `.idle`, `.loading`, `.loaded([Data])`, `.error(String)`).
   - Create `@Published` properties for the View to observe.
   - Write the business logic methods (e.g., `fetchItems()`).
3. **Construct the View:**
   - Bind the UI components to the ViewModel properties.
   - Ensure the View reacts to the `State` enum (e.g., showing a `ProgressView` during `.loading`).
4. **Verify Testability:**
   - Briefly describe how to unit test the ViewModel by mocking the Service layer.

### Coding Standards
- **Language:** Swift 5.10+.
- **Framework Preference:** Default to **SwiftUI + Combine** unless UIKit is explicitly requested.
- **Naming:** ViewModels should be named `[Feature]ViewModel`, and Views should be `[Feature]View`.
- **Binding:** Use `@StateObject` for ViewModel ownership and `@ObservedObject` for dependency injection in SwiftUI.

### Error Handling Policy
Do not use `print()` for errors. All errors must be caught in the ViewModel, mapped to a user-friendly message, and passed to the View via a published error state or alert property. Align with `AppError` for specific recovery suggestions.

## Section 4: Global AI Guidelines
Refer to the system prompt for core AI behavior, tool usage, content policies, and formatting rules. Key points: Use tools for validation, avoid harmful content, follow Microsoft policies, and maintain reproducibility.

---

*Last updated: 2025-12-22*