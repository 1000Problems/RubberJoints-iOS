import Foundation

struct DateHelper {
    static let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles")!

    static var pacificCalendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = pacificTimeZone
        return cal
    }

    /// Today's date at midnight in Pacific time
    static func todayPacific() -> Date {
        let cal = pacificCalendar
        return cal.startOfDay(for: Date())
    }

    /// Today as "yyyy-MM-dd" in Pacific time
    static func todayPacificString() -> String {
        formatDate(Date())
    }

    /// Format any Date to "yyyy-MM-dd" in Pacific time
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = pacificTimeZone
        return formatter.string(from: date)
    }

    /// Parse "yyyy-MM-dd" string to Date (midnight Pacific)
    static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = pacificTimeZone
        return formatter.date(from: string)
    }

    /// Add days to a date
    static func addDays(_ days: Int, to date: Date) -> Date {
        pacificCalendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Day of week name (e.g., "Monday")
    static func dayOfWeekName(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = pacificTimeZone
        return formatter.string(from: date)
    }

    /// Short day name (e.g., "MON")
    static func shortDayName(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = pacificTimeZone
        return formatter.string(from: date).uppercased()
    }

    /// Day number (e.g., "31")
    static func dayNumber(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.timeZone = pacificTimeZone
        return formatter.string(from: date)
    }

    /// Get the week's date strings (Mon-Sun) containing the given date
    static func weekDates(containing dateString: String) -> [String] {
        guard let date = parseDate(dateString) else { return [] }
        let cal = pacificCalendar
        let weekday = cal.component(.weekday, from: date)
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat
        // We want Mon=0 offset
        let mondayOffset = weekday == 1 ? -6 : (2 - weekday)
        guard let monday = cal.date(byAdding: .day, value: mondayOffset, to: date) else { return [] }

        return (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: i, to: monday) ?? monday
            return formatDate(day)
        }
    }

    /// Days between startDate and a given date string
    static func daysBetween(start: Date, end: String) -> Int {
        guard let endDate = parseDate(end) else { return 0 }
        let startDay = pacificCalendar.startOfDay(for: start)
        let endDay = pacificCalendar.startOfDay(for: endDate)
        return pacificCalendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    /// Current week number (1-4) from start date
    static func currentWeek(startDate: Date) -> Int {
        let days = daysBetween(start: startDate, end: todayPacificString())
        return min(max((days / 7) + 1, 1), 4)
    }
}
