# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

- **Build and Deploy to Simulator**: Run `./deploy.sh` to build the app and install it on a specified iOS simulator (e.g., iPhone 17 Pro Max). This script handles cleaning, building with xcodebuild, booting the simulator if needed, uninstalling previous versions, and launching the app.

- **Manual Build in Xcode**: Open `ETPattern.xcodeproj` in Xcode 16.0+, select the `ETPattern` target, choose a device or simulator, and press Cmd + R to build and run.

- **Run Tests**: Use `xcodebuild test -project ETPattern.xcodeproj -scheme ETPattern -destination 'platform=iOS Simulator,name=iPhone 15'` (adjust for your simulator). For a single test, add `-only-testing:ETPatternTests/ClassName/testMethodName`.

- **Linting**: No explicit linting setup found; rely on Xcode's built-in warnings or integrate SwiftLint if needed.

## High-Level Code Architecture

ETPattern is a SwiftUI-based iOS app for spaced-repetition learning, structured as modular Swift Packages for scalability:

- **ETPatternModels**: Defines domain entities like Card, CardSet, StudySession, ReviewLog, and DifficultyRating using SwiftData for persistence.

- **ETPatternCore**: Handles business logic, including the SM-2 spaced repetition algorithm and queue building for study sessions. Depends on ETPatternModels.

- **ETPatternServices**: Manages application services such as session management, CSV importing, file handling, TTS (text-to-speech), and CloudKit synchronization. Depends on ETPatternModels and ETPatternCore.

- **ETPattern (Main App)**: Composes the UI layer with SwiftUI views, view models, and coordinators. Uses MVVM+ architecture. Key components include:
  - Views for study, auto-play, browsing decks, settings, and onboarding.
  - ViewModels for managing state in study, auto-play, and settings.
  - Coordinators for navigation flow (e.g., AppCoordinator, StudyCoordinator).
  - Utilities for design system, extensions, and theme management.

Data flow: User interactions in views trigger view model updates, which interact with services for data operations. Services use core logic for computations and models for data storage. Persistence is handled via SwiftData with CloudKit sync.

## Key README Excerpts

- **Prerequisites**: Xcode 16.0+, iOS 18.0+, Swift 6.0.

- **Data Format**: CSV with double semicolon separators (`Front;;Back;;Tags`), `<br>` for line breaks.

- **Features**: Intelligent SRS with SM-2, Glassmorphism UI, on-device TTS, iPad optimization, self-healing imports.

- **Privacy**: On-device processing, no tracking.