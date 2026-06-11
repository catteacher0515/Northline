import Foundation

enum StressResetQuestion: Int, CaseIterable, Identifiable {
    case q1 = 1
    case q2
    case q3
    case q4
    case q5
    case q6
    case q7
    case q8
    case q9
    case q10

    var id: Int { rawValue }

    var level: StressResetLevel {
        switch self {
        case .q1, .q2, .q3: return .first
        case .q4, .q5: return .second
        case .q6, .q7: return .third
        case .q8, .q9: return .fourth
        case .q10: return .fifth
        }
    }

    var prompt: String {
        switch self {
        case .q1: return "这周我是不是又想同时抓太多事情？"
        case .q2: return "如果只能保 2～3 件事，现在最重要的是哪几件？"
        case .q3: return "我今天最重要的那一件事，写清楚了吗？"
        case .q4: return "我今天有没有至少 20～30 分钟，不继续给焦虑供电？"
        case .q5: return "我休息的时候，是真的在休息，还是换个方式继续想任务？"
        case .q6: return "我最近的身体有没有在报警？"
        case .q7: return "我最近有没有明显的晚睡、疲惫、胸闷、胃不舒服、难专注？"
        case .q8: return "我今天做完一件事后，有没有给自己一点缓冲？"
        case .q9: return "我晚上有没有给今天做收口，还是直接带着悬挂感上床？"
        case .q10: return "我现在是在温和调整自己，还是又开始靠逼迫和自责驱动自己？"
        }
    }
}
