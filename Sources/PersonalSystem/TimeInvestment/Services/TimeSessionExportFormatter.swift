import Foundation

enum TimeSessionExportFormatter {
    static func markdown(
        sessions: [TimeSession],
        startDate: Date,
        endDate: Date,
        calendar: Calendar = .current
    ) -> String {
        let orderedSessions = sessions.sorted { $0.startAt < $1.startAt }
        let startDay = calendar.startOfDay(for: min(startDate, endDate))
        let endDay = calendar.startOfDay(for: max(startDate, endDate))
        let totalRoundedMinutes = orderedSessions.reduce(0) { $0 + ($1.roundedSeconds / 60) }
        let rows = orderedSessions.map { exportRow(for: $0, calendar: calendar) }
        let jsonLines = rows.compactMap(jsonLine(for:)).joined(separator: "\n")

        return """
        # Time Mate 时间记录导出

        ## 范围
        - start_date: \(dayString(startDay, calendar: calendar))
        - end_date: \(dayString(endDay, calendar: calendar))
        - session_count: \(orderedSessions.count)
        - total_rounded_minutes: \(totalRoundedMinutes)

        ## 字段说明
        - date: 本地日期，格式 yyyy-MM-dd
        - start_time / end_time: 本地时间，格式 HH:mm
        - start_at / end_at: ISO 8601 时间戳
        - task_name: 用户结束计时后填写的任务名
        - category: 任务色块分类
        - rounded_minutes: 按 15 分钟四舍五入后的时长
        - actual_minutes: 原始计时时长
        - joy_score: 快乐值，1-10
        - meaning_score: 意义值，1-10
        - note: 用户备注

        ## JSONL
        ```jsonl
        \(jsonLines)
        ```
        """
    }

    private static func exportRow(for session: TimeSession, calendar: Calendar) -> TimeSessionExportRow {
        TimeSessionExportRow(
            date: dayString(session.startAt, calendar: calendar),
            startTime: timeString(session.startAt, calendar: calendar),
            endTime: timeString(session.endAt, calendar: calendar),
            startAt: isoString(session.startAt),
            endAt: isoString(session.endAt),
            taskName: session.taskName ?? "未命名",
            category: session.category.title,
            categoryKey: session.category.rawValue,
            roundedMinutes: session.roundedSeconds / 60,
            actualMinutes: session.durationSeconds / 60,
            joyScore: session.joyScore,
            meaningScore: session.meaningScore,
            note: session.note
        )
    }

    private static func jsonLine(for row: TimeSessionExportRow) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(row) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func dayString(_ date: Date, calendar: Calendar) -> String {
        var localCalendar = calendar
        localCalendar.timeZone = calendar.timeZone
        let components = localCalendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private static func timeString(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private static func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

private struct TimeSessionExportRow: Encodable {
    let date: String
    let startTime: String
    let endTime: String
    let startAt: String
    let endAt: String
    let taskName: String
    let category: String
    let categoryKey: String
    let roundedMinutes: Int
    let actualMinutes: Int
    let joyScore: Int?
    let meaningScore: Int?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case startAt = "start_at"
        case endAt = "end_at"
        case taskName = "task_name"
        case category
        case categoryKey = "category_key"
        case roundedMinutes = "rounded_minutes"
        case actualMinutes = "actual_minutes"
        case joyScore = "joy_score"
        case meaningScore = "meaning_score"
        case note
    }
}
