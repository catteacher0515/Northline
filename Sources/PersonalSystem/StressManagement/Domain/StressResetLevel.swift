import Foundation

enum StressResetLevel: String, Codable, CaseIterable, Equatable, Identifiable {
    case first
    case second
    case third
    case fourth
    case fifth

    var id: String { rawValue }

    var priority: Int {
        switch self {
        case .first: return 1
        case .second: return 2
        case .third: return 3
        case .fourth: return 4
        case .fifth: return 5
        }
    }

    var title: String {
        switch self {
        case .first: return "第一次重置：明确优先级"
        case .second: return "第二次重置：找到一丝宁静"
        case .third: return "第三次重置：身心合一"
        case .fourth: return "第四次重置：喘口气"
        case .fifth: return "第五次重置：展现最好的自己"
        }
    }

    var prompt: String {
        switch self {
        case .first: return "这周最重要的到底是什么？"
        case .second: return "我今天有没有停止给焦虑持续供电？"
        case .third: return "我的身体现在怎么样？"
        case .fourth: return "我今天有没有给自己留缓冲？"
        case .fifth: return "我现在是在调整自己，还是在逼自己证明价值？"
        }
    }

    var action: String {
        switch self {
        case .first:
            return "只保 2～3 件本周核心事项，并写下今天唯一最重要任务。"
        case .second:
            return "给自己留 20～30 分钟，做一件不为产出的停供电动作。"
        case .third:
            return "先检查身体信号，确认今天的睡眠、胸闷、胃和疲惫状态。"
        case .fourth:
            return "现在给自己留一个缓冲，并写下今天做到哪、明天第一步是什么。"
        case .fifth:
            return "暂停自责，提醒自己先做够用版，恢复也算进展。"
        }
    }

    var excerpt: [String] {
        switch self {
        case .first:
            return [
                "不是所有重要的事，都要同时推进",
                "一周只抓 2～3 件核心事项",
                "每天只定 1 个最重要任务"
            ]
        case .second:
            return [
                "停供电时间不是拿来顺便推进一下的",
                "休息不是换个地方继续想任务"
            ]
        case .third:
            return [
                "身体不舒服不是小题大做",
                "也要问我的身体今天扛得住吗"
            ]
        case .fourth:
            return [
                "做完一件事，停 10 分钟",
                "不要把所有空档都拿去补进度"
            ]
        case .fifth:
            return [
                "我不需要靠自责来驱动行动",
                "调整不是退步，是能力"
            ]
        }
    }

    var fullText: [String] {
        switch self {
        case .first:
            return [
                "不是所有重要的事，都要同时推进",
                "一周只抓 2～3 件核心事项",
                "每天只定 1 个最重要任务",
                "大任务一定拆开，不能只写准备实习这种总称"
            ]
        case .second:
            return [
                "停供电时间不是拿来顺便推进一下的",
                "休息不是换个地方继续想任务",
                "可以用 Pocket 3 录给自己、爬坡、听音乐、看脱口秀、不为了产出的表达"
            ]
        case .third:
            return [
                "身体不舒服不是小题大做",
                "睡眠乱、胸闷、头昏、胃不舒服，都是压力信号",
                "不要只问今天做了多少事，也要问身体今天扛得住吗"
            ]
        case .fourth:
            return [
                "做完一件事，停 10 分钟",
                "每天只设 1 个主任务块",
                "晚上做收口：写下今天做到哪，明天第一步是什么"
            ]
        case .fifth:
            return [
                "我不需要靠自责来驱动行动",
                "状态波动不等于我不行",
                "先做够用版，再慢慢变好",
                "恢复也算进展"
            ]
        }
    }
}
