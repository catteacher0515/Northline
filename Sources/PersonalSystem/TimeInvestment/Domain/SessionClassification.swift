import Foundation

enum SessionClassification: String, Codable, CaseIterable, Equatable {
    case production
    case consumption
}

enum TimeSessionCategory: String, Codable, CaseIterable, Equatable, Identifiable {
    case sleep
    case foodExercise
    case studyWork
    case entertainment
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep:
            return "睡眠"
        case .foodExercise:
            return "做饭/吃饭/运动"
        case .studyWork:
            return "学习/工作"
        case .entertainment:
            return "娱乐"
        case .other:
            return "其他"
        }
    }

    static func classify(taskName: String) -> TimeSessionCategory {
        if taskName.range(of: "睡", options: [.caseInsensitive, .regularExpression]) != nil {
            return .sleep
        }

        if taskName.range(of: "饭|吃|做饭|运动|跑步|健身", options: [.caseInsensitive, .regularExpression]) != nil {
            return .foodExercise
        }

        if taskName.range(of: "学|工|实习|写作|编码|代码|阅读", options: [.caseInsensitive, .regularExpression]) != nil {
            return .studyWork
        }

        if taskName.range(of: "视频|游戏|刷|娱乐|抖音|小红书", options: [.caseInsensitive, .regularExpression]) != nil {
            return .entertainment
        }

        return .other
    }

    var legacyClassification: SessionClassification {
        switch self {
        case .studyWork:
            return .production
        case .sleep, .foodExercise, .entertainment, .other:
            return .consumption
        }
    }
}
