import Foundation
import XCTest
@testable import PersonalSystem

final class TimeSessionStoreTests: XCTestCase {
    func testDailyTotalsSeparateRecordedCategories() {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))

        let study = TimeSession(
            startAt: startOfDay,
            endAt: startOfDay.addingTimeInterval(1_800),
            referenceDurationSeconds: 1_500,
            taskName: "实习工作",
            category: .studyWork,
            joyScore: 7,
            meaningScore: 9,
            note: "进入状态之后很顺",
            endedByUser: true
        )

        let entertainment = TimeSession(
            startAt: startOfDay.addingTimeInterval(2_000),
            endAt: startOfDay.addingTimeInterval(3_200),
            referenceDurationSeconds: 1_500,
            taskName: "刷视频",
            category: .entertainment,
            joyScore: 4,
            meaningScore: 2,
            note: nil,
            endedByUser: true
        )

        let totals = TimeSessionStore.dailyTotals(
            sessions: [study, entertainment],
            now: startOfDay.addingTimeInterval(4_000),
            calendar: calendar
        )

        XCTAssertEqual(totals.productionSeconds, 1_800)
        XCTAssertEqual(totals.consumptionSeconds, 1_200)
    }

    func testSessionDraftClassifiesTaskAndStoresSubjectiveScores() {
        let draft = SessionDraftResult(
            taskName: "晚上刷视频",
            category: nil,
            joyScore: 5,
            meaningScore: 2,
            note: "  超过半小时之后就没意思了  "
        )

        let session = draft.makeSession(
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 2_000),
            referenceDurationSeconds: 1_500
        )

        XCTAssertEqual(session.taskName, "晚上刷视频")
        XCTAssertEqual(session.category, .entertainment)
        XCTAssertEqual(session.joyScore, 5)
        XCTAssertEqual(session.meaningScore, 2)
        XCTAssertEqual(session.note, "超过半小时之后就没意思了")
    }

    func testSessionDurationRoundsToNearestQuarterHour() {
        let session = TimeSession(
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 100 + 8 * 60),
            referenceDurationSeconds: 1_500,
            taskName: "学习",
            category: .studyWork,
            joyScore: nil,
            meaningScore: nil,
            note: nil,
            endedByUser: true
        )

        let normalized = session.normalizedForPersistence()

        XCTAssertEqual(normalized.roundedDurationSeconds, 15 * 60)
    }

    func testBlankTaskFallsBackToOther() {
        let session = TimeSession(
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 400),
            referenceDurationSeconds: 1_500,
            taskName: "   ",
            category: .studyWork,
            joyScore: 99,
            meaningScore: 0,
            note: "   ",
            endedByUser: true
        )

        let normalized = session.normalizedForPersistence()

        XCTAssertEqual(normalized.taskName, "未命名")
        XCTAssertEqual(normalized.category, .other)
        XCTAssertEqual(normalized.joyScore, 10)
        XCTAssertEqual(normalized.meaningScore, 1)
        XCTAssertNil(normalized.note)
    }

    @MainActor
    func testViewModelReturnsSessionsForSelectedDay() {
        let calendar = Calendar(identifier: .gregorian)
        let targetDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))
        let previousDay = calendar.date(byAdding: .day, value: -1, to: targetDay) ?? targetDay

        let todaySession = TimeSession(
            startAt: targetDay.addingTimeInterval(9 * 3_600),
            endAt: targetDay.addingTimeInterval(10 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "学习",
            category: .studyWork,
            joyScore: 7,
            meaningScore: 9,
            note: nil,
            endedByUser: true
        )
        let oldSession = TimeSession(
            startAt: previousDay.addingTimeInterval(21 * 3_600),
            endAt: previousDay.addingTimeInterval(22 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "刷视频",
            category: .entertainment,
            joyScore: 5,
            meaningScore: 2,
            note: nil,
            endedByUser: true
        )
        let viewModel = TimeInvestmentViewModel(
            store: InMemoryTimeSessionStore(seedSessions: [oldSession, todaySession]),
            timer: SessionTimer(),
            referenceDurationSeconds: 1_500
        )

        let result = viewModel.sessions(on: targetDay, calendar: calendar)

        XCTAssertEqual(result.map { $0.taskName }, ["学习"])
    }

    @MainActor
    func testViewModelReturnsSessionsInDateRange() {
        let calendar = Calendar(identifier: .gregorian)
        let startDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startDay) ?? startDay
        let afterRange = calendar.date(byAdding: .day, value: 2, to: startDay) ?? startDay

        let first = TimeSession(
            startAt: startDay.addingTimeInterval(9 * 3_600),
            endAt: startDay.addingTimeInterval(10 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "学习",
            category: .studyWork,
            joyScore: 7,
            meaningScore: 9,
            note: nil,
            endedByUser: true
        )
        let second = TimeSession(
            startAt: nextDay.addingTimeInterval(8 * 3_600),
            endAt: nextDay.addingTimeInterval(9 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "早餐",
            category: .foodExercise,
            joyScore: 7,
            meaningScore: 6,
            note: nil,
            endedByUser: true
        )
        let third = TimeSession(
            startAt: afterRange.addingTimeInterval(21 * 3_600),
            endAt: afterRange.addingTimeInterval(22 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "刷视频",
            category: .entertainment,
            joyScore: 5,
            meaningScore: 2,
            note: nil,
            endedByUser: true
        )
        let viewModel = TimeInvestmentViewModel(
            store: InMemoryTimeSessionStore(seedSessions: [third, second, first]),
            timer: SessionTimer(),
            referenceDurationSeconds: 1_500
        )

        let result = viewModel.sessions(from: startDay, to: nextDay, calendar: calendar)

        XCTAssertEqual(result.map { $0.taskName }, ["学习", "早餐"])
    }

    @MainActor
    func testViewModelReturnsInclusiveDaysInRange() {
        let calendar = Calendar(identifier: .gregorian)
        let startDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))
        let endDay = calendar.date(byAdding: .day, value: 2, to: startDay) ?? startDay
        let viewModel = TimeInvestmentViewModel(
            store: InMemoryTimeSessionStore(seedSessions: []),
            timer: SessionTimer(),
            referenceDurationSeconds: 1_500
        )

        let days = viewModel.days(from: startDay, to: endDay, calendar: calendar)

        XCTAssertEqual(days, [
            startDay,
            calendar.date(byAdding: .day, value: 1, to: startDay),
            endDay
        ])
    }

    func testExportFormatterIncludesReadableContextAndJSONLines() {
        let calendar = Calendar(identifier: .gregorian)
        let startDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))
        let session = TimeSession(
            startAt: startDay.addingTimeInterval(9 * 3_600),
            endAt: startDay.addingTimeInterval(10 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "学习",
            category: .studyWork,
            joyScore: 7,
            meaningScore: 9,
            note: "推进核心任务",
            endedByUser: true
        )

        let export = TimeSessionExportFormatter.markdown(
            sessions: [session],
            startDate: startDay,
            endDate: startDay,
            calendar: calendar
        )

        XCTAssertTrue(export.contains("# Time Mate 时间记录导出"))
        XCTAssertTrue(export.contains("字段说明"))
        XCTAssertTrue(export.contains("\"task_name\":\"学习\""))
        XCTAssertTrue(export.contains("\"category\":\"学习/工作\""))
        XCTAssertTrue(export.contains("\"rounded_minutes\":60"))
        XCTAssertTrue(export.contains("\"note\":\"推进核心任务\""))
    }

    func testExportPackageContainsAnalysisFiles() {
        let calendar = Calendar(identifier: .gregorian)
        let startDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))
        let study = TimeSession(
            startAt: startDay.addingTimeInterval(9 * 3_600),
            endAt: startDay.addingTimeInterval(10 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "学习",
            category: .studyWork,
            joyScore: 7,
            meaningScore: 9,
            note: "推进核心任务",
            endedByUser: true
        )
        let entertainment = TimeSession(
            startAt: startDay.addingTimeInterval(21 * 3_600),
            endAt: startDay.addingTimeInterval(22 * 3_600),
            referenceDurationSeconds: 1_500,
            taskName: "刷视频",
            category: .entertainment,
            joyScore: 5,
            meaningScore: 2,
            note: nil,
            endedByUser: true
        )

        let package = TimeSessionExportFormatter.package(
            sessions: [entertainment, study],
            startDate: startDay,
            endDate: startDay,
            calendar: calendar
        )

        XCTAssertEqual(Set(package.files.keys), [
            "README.md",
            "sessions.jsonl",
            "sessions.csv",
            "daily_summary.json"
        ])
        XCTAssertTrue(package.folderName.hasPrefix("TimeMate-Export-"))
        XCTAssertTrue(package.files["sessions.jsonl"]?.contains("\"task_name\":\"学习\"") == true)
        XCTAssertTrue(package.files["sessions.csv"]?.contains("date,start_time,end_time,task_name,category") == true)
        XCTAssertTrue(package.files["daily_summary.json"]?.contains("\"total_recorded_minutes\" : 120") == true)
        XCTAssertTrue(package.files["README.md"]?.contains("给大模型分析的建议") == true)
    }
}
