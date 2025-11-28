//
//  Extensions.swift
//  ETPattern
//
//  Created by admin on 28/11/2025.
//

import Foundation
import UIKit

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