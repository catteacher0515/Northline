import Foundation

struct TimeSessionExportPackage: Equatable {
    let folderName: String
    let files: [String: String]
}

enum TimeSessionExportFormatter {
    static func package(
        sessions: [TimeSession],
        startDate: Date,
        endDate: Date,
        calendar: Calendar = .current
    ) -> TimeSessionExportPackage {
        let orderedSessions = sessions.sorted { $0.startAt < $1.startAt }
        let startDay = calendar.startOfDay(for: min(startDate, endDate))
        let endDay = calendar.startOfDay(for: max(startDate, endDate))
        let rows = orderedSessions.map { exportRow(for: $0, calendar: calendar) }
        let folderName = "TimeMate-Export-\(dayString(startDay, calendar: calendar))-to-\(dayString(endDay, calendar: calendar))"

        return TimeSessionExportPackage(
            folderName: folderName,
            files: [
                "README.md": readme(
                    sessions: orderedSessions,
                    startDay: startDay,
                    endDay: endDay,
                    calendar: calendar
                ),
                "sessions.jsonl": rows.compactMap(jsonLine(for:)).joined(separator: "\n"),
                "sessions.csv": csv(for: rows),
                "daily_summary.json": dailySummaryJSON(
                    sessions: orderedSessions,
                    startDay: startDay,
                    endDay: endDay,
                    calendar: calendar
                )
            ]
        )
    }

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

    private static func readme(
        sessions: [TimeSession],
        startDay: Date,
        endDay: Date,
        calendar: Calendar
    ) -> String {
        let totalRoundedMinutes = sessions.reduce(0) { $0 + ($1.roundedSeconds / 60) }

        return """
        # Time Mate 时间记录导出

        ## 范围
        - start_date: \(dayString(startDay, calendar: calendar))
        - end_date: \(dayString(endDay, calendar: calendar))
        - session_count: \(sessions.count)
        - total_rounded_minutes: \(totalRoundedMinutes)
        - minimum_time_block: 15 minutes

        ## 文件说明
        - `sessions.jsonl`: 主分析数据，每行一条时间记录，最适合给大模型或脚本逐条读取。
        - `daily_summary.json`: 按天聚合后的摘要，适合趋势分析和周/月复盘。
        - `sessions.csv`: 表格兼容格式，适合导入 Numbers、Excel、飞书表格。
        - `README.md`: 当前文件，说明数据范围、字段含义和分析建议。

        ## 字段说明
        - date: 本地日期，格式 yyyy-MM-dd
        - start_time / end_time: 本地时间，格式 HH:mm
        - start_at / end_at: ISO 8601 时间戳
        - task_name: 用户结束计时后填写的任务名
        - category: 任务色块分类
        - category_key: 程序内部分类 key
        - rounded_minutes: 按 15 分钟四舍五入后的时长
        - actual_minutes: 原始计时时长
        - joy_score: 快乐值，1-10
        - meaning_score: 意义值，1-10
        - note: 用户备注

        ## 给大模型分析的建议
        1. 先读取 `README.md` 理解记录规则。
        2. 用 `daily_summary.json` 判断整体趋势和分类占比。
        3. 用 `sessions.jsonl` 回到具体记录，分析任务、备注、快乐值和意义值之间的关系。
        4. 空白时间代表未记录，不要直接推断为休息或娱乐。
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

    private static func csv(for rows: [TimeSessionExportRow]) -> String {
        let header = [
            "date",
            "start_time",
            "end_time",
            "task_name",
            "category",
            "category_key",
            "rounded_minutes",
            "actual_minutes",
            "joy_score",
            "meaning_score",
            "note",
            "start_at",
            "end_at"
        ].joined(separator: ",")

        let lines = rows.map { row in
            [
                row.date,
                row.startTime,
                row.endTime,
                row.taskName,
                row.category,
                row.categoryKey,
                String(row.roundedMinutes),
                String(row.actualMinutes),
                row.joyScore.map(String.init) ?? "",
                row.meaningScore.map(String.init) ?? "",
                row.note ?? "",
                row.startAt,
                row.endAt
            ]
            .map(csvEscaped)
            .joined(separator: ",")
        }

        return ([header] + lines).joined(separator: "\n")
    }

    private static func dailySummaryJSON(
        sessions: [TimeSession],
        startDay: Date,
        endDay: Date,
        calendar: Calendar
    ) -> String {
        let summaries = dailySummaries(
            sessions: sessions,
            startDay: startDay,
            endDay: endDay,
            calendar: calendar
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard let data = try? encoder.encode(summaries),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return string
    }

    private static func dailySummaries(
        sessions: [TimeSession],
        startDay: Date,
        endDay: Date,
        calendar: Calendar
    ) -> [DailyExportSummary] {
        var result: [DailyExportSummary] = []
        var current = startDay

        while current <= endDay {
            let next = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            let daySessions = sessions.filter { $0.startAt >= current && $0.startAt < next }
            let categoryMinutes = Dictionary(
                grouping: daySessions,
                by: { $0.category.title }
            )
            .mapValues { sessions in
                sessions.reduce(0) { $0 + ($1.roundedSeconds / 60) }
            }
            let joyScores = daySessions.compactMap(\.joyScore)
            let meaningScores = daySessions.compactMap(\.meaningScore)

            result.append(
                DailyExportSummary(
                    date: dayString(current, calendar: calendar),
                    totalRecordedMinutes: daySessions.reduce(0) { $0 + ($1.roundedSeconds / 60) },
                    categoryMinutes: categoryMinutes,
                    averageJoyScore: average(joyScores),
                    averageMeaningScore: average(meaningScores)
                )
            )

            guard next > current else {
                break
            }
            current = next
        }

        return result
    }

    private static func average(_ values: [Int]) -> Double? {
        guard values.isEmpty == false else {
            return nil
        }

        let raw = Double(values.reduce(0, +)) / Double(values.count)
        return (raw * 10).rounded() / 10
    }

    private static func csvEscaped(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }

        return value
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

private struct DailyExportSummary: Encodable, Equatable {
    let date: String
    let totalRecordedMinutes: Int
    let categoryMinutes: [String: Int]
    let averageJoyScore: Double?
    let averageMeaningScore: Double?

    enum CodingKeys: String, CodingKey {
        case date
        case totalRecordedMinutes = "total_recorded_minutes"
        case categoryMinutes = "category_minutes"
        case averageJoyScore = "average_joy_score"
        case averageMeaningScore = "average_meaning_score"
    }
}
