//
//  Extensions.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
import Combine

extension String {
    func htmlToAttributedString() -> AttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            let nsAttributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
            return AttributedString(nsAttributedString)
        } catch {
            return nil
        }
    }
}

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    func daysUntil() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: self)
        return components.day ?? 0
    }
}

extension Int {
    var days: TimeInterval {
        return TimeInterval(self * 86400)
    }
}

// MARK: - Haptic Feedback
#if os(iOS)
extension UIImpactFeedbackGenerator {
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

extension UINotificationFeedbackGenerator {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
#endif

// MARK: - View Extensions
extension View {
    #if os(iOS)
    func withHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, onTap: @escaping () -> Void) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            onTap()
        }
    }

    func withSuccessHaptic() -> some View {
        self.onTapGesture {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func withErrorHaptic() -> some View {
        self.onTapGesture {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    #else
    // Fallback or empty implementations for macOS
    func withHapticFeedback(onTap: @escaping () -> Void) -> some View {
        self.onTapGesture {
            onTap()
        }
    }

    func withSuccessHaptic() -> some View {
        self
    }

    func withErrorHaptic() -> some View {
        self
    }
    #endif

    func withSpringAnimation() -> some View {
        self.animation(.spring(response: 0.3, dampingFraction: 0.7), value: UUID())
    }

    func withEaseInOutAnimation(duration: Double = 0.3) -> some View {
        self.animation(.easeInOut(duration: duration), value: UUID())
    }

    func withBouncyAnimation() -> some View {
        self.animation(.bouncy, value: UUID())
    }
}

// MARK: - Animation Extensions
extension Animation {
    static var bouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }

    static var smooth: Animation {
        .easeInOut(duration: 0.3)
    }

    static var snappy: Animation {
        .spring(response: 0.2, dampingFraction: 0.8)
    }
}

extension View {
    @ViewBuilder
    func fullScreenCoverIfiOS<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, content: content)
        #else
        self
        #endif
    }

    @ViewBuilder
    func fullScreenCoverIfiOS<Item: Identifiable, Content: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        self
        #endif
    }

    @ViewBuilder
    func navigationBarHiddenIfiOS(_ hidden: Bool) -> some View {
        #if os(iOS)
        navigationBarHidden(hidden)
        #else
        self
        #endif
    }

    @ViewBuilder
    func tabViewStyleIfiOS<T: TabViewStyle>(_ style: T) -> some View {
        #if os(iOS)
        tabViewStyle(style)
        #else
        self
        #endif
    }

    @ViewBuilder
    func translationTaskIfiOS(_ configuration: TranslationSession.Configuration, _ action: @escaping (TranslationSession) -> Void) -> some View {
        #if os(iOS)
        translationTask(configuration, action)
        #else
        self
        #endif
    }
}

// MARK: - Combine Memory Management Helpers
extension ObservableObject where Self: AnyObject {
    /// Safely subscribe to a publisher with automatic cancellable storage
    /// - Parameters:
    ///   - publisher: The publisher to subscribe to
    ///   - cancellables: The set to store the cancellable in
    ///   - receiveValue: The closure to execute when receiving values
    /// - Returns: The cancellable (automatically stored)
    @discardableResult
    func subscribe<P: Publisher>(
        to publisher: P,
        storeIn cancellables: inout Set<AnyCancellable>,
        receiveValue: @escaping (P.Output) -> Void
    ) -> AnyCancellable where P.Failure == Never {
        let cancellable = publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
        cancellables.insert(cancellable)
        return cancellable
    }
    
    /// Safely subscribe to a publisher with weak self capture
    /// - Parameters:
    ///   - publisher: The publisher to subscribe to
    ///   - cancellables: The set to store the cancellable in
    ///   - receiveValue: The closure to execute when receiving values (with weak self)
    /// - Returns: The cancellable (automatically stored)
    @discardableResult
    func subscribeWeak<P: Publisher>(
        to publisher: P,
        storeIn cancellables: inout Set<AnyCancellable>,
        receiveValue: @escaping (Self, P.Output) -> Void
    ) -> AnyCancellable where P.Failure == Never {
        let cancellable = publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                receiveValue(self, value)
            }
        cancellables.insert(cancellable)
        return cancellable
    }
}