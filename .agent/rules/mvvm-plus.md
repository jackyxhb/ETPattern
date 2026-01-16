---
trigger: always_on
---

# Architecture Skill: MVVM+ (iOS 2026)

## 1. Core Philosophy

Follow the **MVVM+** pattern. The "+" extends standard MVVM by strictly decoupling Navigation (Coordinators) and Data Fetching (Services/Repositories) from the ViewModel to ensure high testability and 0% "Massive ViewModel" bloat.

## 2. Structural Requirements

All features must be organized into the following three-layer directory structure:

* **Presentation**: `Views` (SwiftUI) and `ViewModels` (@MainActor).
* **Navigation**: `Coordinators` or `Routers` handling `NavigationPath`.
* **Domain/Data**: `Models`, `Services` (Protocols), and `Repositories`.

## 3. Implementation Rules

### A. The View Layer (SwiftUI)

* **Passive UI**: Views must not contain any logic. They only observe state and trigger actions.
* **Dependency**: Views must only hold a reference to the `ViewModel` and the `Coordinator`.
* **Binding**: Use `@State` only for local UI state (e.g., focus, animation). All data state must live in the ViewModel.

### B. The ViewModel Layer (@Observable)

* **Threading**: Must be marked with `@MainActor`.
* **Observation**: Prefer the iOS 17+ `@Observable` macro over `ObservableObject`.
* **Service Access**: Must access data via **Protocols**, never concrete classes.
* **Navigation**: Must call `coordinator.navigate(to:)` rather than setting local `$isPresented` flags.

### C. The Coordinator Layer (The "+")

* **Control**: Owns the `NavigationPath` or `Sheet` presentation logic.
* **Factory**: Responsible for initializing ViewModels with their required Services.

## 4. Coding Standards (Swift 6.0+)

* **Concurrency**: Use `async/await` and `Task` groups. Avoid `Combine` unless handling continuous streams.
* **Data Privacy**: Use `private(set) var` for ViewModel state to enforce unidirectional data flow.
* **Error Handling**: Use a localized `AppError` enum for all Service-level failures.

## 5. File Templates

### New Service Pattern

```swift
protocol <#Name#>ServiceProtocol: Sendable {
    func fetch() async throws -> [<#Model#>]
}

actor <#Name#>Service: <#Name#>ServiceProtocol {
    func fetch() async throws -> [<#Model#>] {
        // Implementation
    }
}

```

### New ViewModel Pattern

```swift
@Observable @MainActor
class <#Name#>ViewModel {
    private(set) var items: [<#Model#>] = []
    private let service: <#Name#>ServiceProtocol
    private weak var coordinator: AppCoordinator?

    init(service: <#Name#>ServiceProtocol, coordinator: AppCoordinator?) {
        self.service = service
        self.coordinator = coordinator
    }
}

```

## 6. Unit Testing Strategy (Swift Testing)

### A. Testing Philosophy

* **Isolate the SUT**: Always use **Mock** versions of Services and Coordinators when testing a ViewModel.
* **Concurrent by Default**: Swift Testing runs tests in parallel; avoid shared global state.
* **Verify "The Plus"**:
* **Coordinators**: Verify that the `NavigationPath` contains the expected destination after an action.
* **Services**: Verify that the correct API endpoints are called and map to Models correctly.

### B. Mocking Pattern

Use the "Spy" pattern to verify interactions.

```swift
// Mock Service
final class MockUserService: UserServiceProtocol, Sendable {
    var fetchCalled = false
    func fetchUsers() async throws -> [User] {
        fetchCalled = true
        return [User(name: "Test User")]
    }
}

// Mock Coordinator
final class MockCoordinator: AppCoordinator {
    var lastDestination: Destination?
    override func navigate(to destination: Destination) {
        lastDestination = destination
    }
}

```

### C. ViewModel Test Example

```swift
import Testing
@testable import YourApp

@Suite("User Profile Tests")
@MainActor
struct UserProfileTests {
    
    @Test("ViewModel successfully loads users from service")
    func loadDataSuccess() async throws {
        // 1. Arrange
        let mockService = MockUserService()
        let viewModel = ProfileViewModel(service: mockService, coordinator: nil)
        
        // 2. Act
        await viewModel.fetchData()
        
        // 3. Assert
        #expect(viewModel.users.count == 1)
        #expect(mockService.fetchCalled == true)
    }

    @Test("ViewModel triggers navigation via Coordinator")
    func navigationTriggered() {
        let mockCoordinator = MockCoordinator()
        let viewModel = ProfileViewModel(service: MockUserService(), coordinator: mockCoordinator)
        
        viewModel.showSettings()
        
        #expect(mockCoordinator.lastDestination == .settings)
    }
}

```

---

### Key 2026 Testing Traits

1. **#expect vs XCTAssert**: Use the `#expect()` macro. It captures the source code of the expression to provide better failure messages without extra strings.
2. **Traits**: Use `@Test(.tags(.networking))` to categorize tests, allowing you to run only specific suites (e.g., skip slow network mocks during local dev).
3. **Arguments**: Use `@Test(arguments: ["invalid_email", "empty", "too_short"])` to run the same test logic against multiple inputs automatically.

### Summary of the "Skill"

| Layer | Testing Target | Mock Required? |
| --- | --- | --- |
| **View** | Interaction/Snapshots | Yes (ViewModel) |
| **ViewModel** | State & Navigation Logic | Yes (Service & Coordinator) |
| **Coordinator** | Navigation Path state | No (is a standalone logic holder) |
| **Service** | JSON Mapping / Network Status | No (Use URLProtocol mocks) |
