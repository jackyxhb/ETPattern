import SwiftUI

#if canImport(UIKit)
import UIKit

public extension UIImpactFeedbackGenerator {
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
}

public extension UINotificationFeedbackGenerator {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
#else
// Mock implementations for non-UIKit platforms (e.g. macOS testing)
public class UIImpactFeedbackGenerator {
    public enum FeedbackStyle { case light, medium, heavy }
    public init(style: FeedbackStyle) {}
    public func prepare() {}
    public func impactOccurred() {}
    public static func lightImpact() {}
    public static func mediumImpact() {}
    public static func heavyImpact() {}
}

public class UINotificationFeedbackGenerator {
    public enum FeedbackType { case success, warning, error }
    public init() {}
    public func prepare() {}
    public func notificationOccurred(_ type: FeedbackType) {}
    public static func success() {}
    public static func warning() {}
    public static func error() {}
}
#endif
