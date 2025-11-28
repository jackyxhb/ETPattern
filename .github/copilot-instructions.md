# ETPattern - AI Coding Guidelines

## Architecture Overview
This is a SwiftUI iOS application with Core Data persistence. The app follows Apple's standard MVVM pattern with SwiftUI views and Core Data for data management.

**Key Components:**
- `ETPatternApp.swift` - Main app entry point with Core Data context injection
- `ContentView.swift` - Primary UI showing a list of timestamped items
- `Persistence.swift` - Core Data stack management with shared and preview controllers
- `ETPattern.xcdatamodeld` - Data model with `Item` entity (timestamp attribute)

## Development Workflow

### Building
```bash
xcodebuild -project ETPattern.xcodeproj -scheme ETPattern -sdk iphonesimulator -configuration Debug build
```
- Builds for iOS Simulator by default
- Uses SDK version 26.1 (iOS 18.1 simulator)
- Debug configuration includes full debugging symbols

### Testing
- Unit tests in `ETPatternTests/` (currently empty template)
- UI tests in `ETPatternUITests/` with launch performance measurement
- Run via Xcode or `xcodebuild test`

## Code Patterns

### Core Data Usage
- Use `PersistenceController.shared` for production data access
- Use `PersistenceController.preview` for SwiftUI previews with sample data
- Follow standard Core Data patterns: `@FetchRequest`, `@Environment(\.managedObjectContext)`
- Error handling uses `fatalError` in development (replace with proper error handling for production)

### SwiftUI Patterns
- NavigationView with List for master-detail interfaces
- `@FetchRequest` for reactive data binding
- Standard toolbar items (EditButton, plus button)
- Date formatting with `DateFormatter` (short date, medium time style)

### File Organization
- Main source in `ETPattern/` directory
- Tests in separate `ETPatternTests/` and `ETPatternUITests/` directories
- Assets in `Assets.xcassets/` (standard iOS asset catalog)

## Dependencies
- SwiftUI framework (iOS 18.1+)
- CoreData framework
- Foundation framework (implicit)

## Conventions
- Standard Swift naming conventions
- 4-space indentation (Xcode default)
- Use of SwiftUI property wrappers (`@Environment`, `@FetchRequest`)
- Preview support with `#Preview` macro
- Force unwrap optionals in development code (replace with proper unwrapping for production)

## Key Files to Reference
- `ContentView.swift` - Exemplifies SwiftUI + Core Data integration
- `Persistence.swift` - Shows proper Core Data setup patterns
- `ETPatternApp.swift` - Demonstrates app-wide dependency injection