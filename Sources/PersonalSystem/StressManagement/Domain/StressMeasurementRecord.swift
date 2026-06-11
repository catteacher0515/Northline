import Foundation

enum StressPressureLevel: String, Codable, Equatable {
    case low
    case moderate
    case high

    static func from(totalScore: Int) -> StressPressureLevel {
        switch totalScore {
        case 0...6:
            return .low
        case 7...13:
            return .moderate
        default:
            return .high
        }
    }

    var title: String {
        switch self {
        case .low:
            return "低压"
        case .moderate:
            return "中压"
        case .high:
            return "高压"
        }
    }
}

struct StressMeasurementRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var createdAt: Date
    var scores: [Int: Int]
    var totalScore: Int
    var pressureLevelRawValue: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        scores: [Int: Int]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.scores = scores
        self.totalScore = scores.values.reduce(0, +)
        self.pressureLevelRawValue = StressPressureLevel.from(totalScore: totalScore).rawValue
    }

    var pressureLevel: StressPressureLevel {
        StressPressureLevel(rawValue: pressureLevelRawValue) ?? .moderate
    }
}
