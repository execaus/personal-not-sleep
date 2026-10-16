import Foundation
import PersonalNotSleepCore

let calendar: Calendar = {
    var result = Calendar(identifier: .gregorian)
    result.timeZone = TimeZone(secondsFromGMT: 0)!
    result.firstWeekday = 2
    return result
}()
func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day,
                                       hour: hour, minute: minute))!
}
func check(_ condition: Bool, _ name: String) {
    guard condition else { fputs("FAIL: \(name)\n", stderr); exit(1) }
    print("OK: \(name)")
}
let daytime = ScheduleRule(weekdays: [2, 3], startMinute: 540, endMinute: 600)
check(ScheduleEvaluator.activeIntervals(at: date(2026, 10, 19, 9), rules: [daytime], calendar: calendar).count == 1, "weekday start")
check(ScheduleEvaluator.activeIntervals(at: date(2026, 10, 19, 10), rules: [daytime], calendar: calendar).isEmpty, "exclusive end")
check(ScheduleEvaluator.activeIntervals(at: date(2026, 10, 21, 9), rules: [daytime], calendar: calendar).isEmpty, "weekday filter")
let overnight = ScheduleRule(weekdays: [2], startMinute: 1380, endMinute: 60)
check(ScheduleEvaluator.activeIntervals(at: date(2026, 10, 20, 0, 30), rules: [overnight], calendar: calendar).count == 1, "overnight")
check(ScheduleEvaluator.activeIntervals(at: date(2026, 10, 20, 1), rules: [overnight], calendar: calendar).isEmpty, "overnight end")
var state = HoldState()
state.stop(at: date(2026, 10, 19, 9, 30), rules: [daytime], calendar: calendar)
check(state.evaluate(at: date(2026, 10, 19, 9, 45), rules: [daytime], calendar: calendar) == .inactive, "manual suppression")
check(state.evaluate(at: date(2026, 10, 19, 10), rules: [daytime], calendar: calendar) == .inactive, "suppression clears")
if case .schedule = state.evaluate(at: date(2026, 10, 20, 9), rules: [daytime], calendar: calendar) {
    print("OK: next interval")
} else { check(false, "next interval") }
state.timerEnd = date(2026, 10, 20, 10)
check(state.evaluate(at: date(2026, 10, 20, 9), rules: [], calendar: calendar) == .timer(date(2026, 10, 20, 10)), "timer active")
check(state.evaluate(at: date(2026, 10, 20, 10), rules: [], calendar: calendar) == .inactive, "timer expired")
let invalid = ScheduleRule(weekdays: [2], startMinute: 540, endMinute: 540)
check(ScheduleEvaluator.activeIntervals(at: date(2026, 10, 19, 9), rules: [invalid], calendar: calendar).isEmpty, "invalid rule")
