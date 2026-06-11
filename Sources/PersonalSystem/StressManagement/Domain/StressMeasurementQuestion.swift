import Foundation

enum StressMeasurementQuestion: Int, CaseIterable, Identifiable {
    case q1 = 1
    case q2
    case q3
    case q4
    case q5

    var id: Int { rawValue }

    var prompt: String {
        switch self {
        case .q1: return "过去的一个月，你内心的金丝雀向你发出预警的频率是？"
        case .q2: return "过去的一个月，压力让你不堪重负或心神不安的频率是？"
        case .q3: return "过去的一个月，压力让你感到筋疲力尽或精神不振的频率是？"
        case .q4: return "过去的一个月，因为压力巨大而睡眠中断的频率是？"
        case .q5: return "过去的一个月，压力影响到你日常生活的频率是？"
        }
    }

    static let scoreLabels: [Int: String] = [
        0: "从不",
        1: "几乎没有",
        2: "有时",
        3: "比较频繁",
        4: "非常频繁"
    ]
}
