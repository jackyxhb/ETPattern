import Foundation

public enum StudyStrategy: String, Codable, CaseIterable, Sendable {
    /// Cards ordered by their original sequence (usually ID).
    case linear
    /// Cards purely shuffled.
    case shuffled
    /// SRS Priority: Due/Lapses first, then New cards, then Mature cards.
    case intelligent
    
    public var displayName: String {
        switch self {
        case .linear: return "Sequential"
        case .shuffled: return "Random"
        case .intelligent: return "Intelligent"
        }
    }
    
    public var icon: String {
        switch self {
        case .linear: return "arrow.right.circle"
        case .shuffled: return "shuffle"
        case .intelligent: return "brain"
        }
    }
}
