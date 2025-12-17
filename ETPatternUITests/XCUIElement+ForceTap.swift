import XCTest

extension XCUIElement {
    /// More robust than `tap()` for UI tests where the element exists but is not hittable
    /// (e.g., XCUITest tries and fails to perform an AX scroll-to-visible action).
    func forceTap(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(self.exists, "Element does not exist", file: file, line: line)

        if self.isHittable {
            self.tap()
            return
        }

        // Coordinate taps can succeed even when XCUITest considers the element not hittable.
        let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}
