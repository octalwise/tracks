import Foundation
import SwiftSoup

struct Holidays {
    var holidays: [(day: Int, month: Int)]

    init(html: String) {
        holidays = []

        do {
            let doc = try SwiftSoup.parse(html)

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = laTz
            formatter.dateFormat = "MMMM d"

            for row in try doc.select("table.holiday-service-schedule tbody tr") {
                let vals = try row.select("td")

                if try vals.get(2).text() != "Weekend Schedule*" {
                    continue
                }

                guard let time = formatter.date(from: try vals.get(1).text()) else {
                    throw FormatError.formatError("Invalid time format in Caltrain data.")
                }

                let comps = laCalendar.dateComponents([.day, .month], from: time)
                holidays.append((day: comps.day!, month: comps.month!))
            }
        } catch {
            holidays = []
        }
    }

    func isHoliday(_ date: Date) -> Bool {
        let comps = laCalendar.dateComponents([.day, .month], from: date)
        return holidays.contains { $0.day == comps.day! && $0.month == comps.month! }
    }

    func service() -> String {
        let shifted = laCalendar.date(byAdding: .hour, value: -3, to: Date())!
        let isWeekend = laCalendar.isDateInWeekend(shifted)

        return (isWeekend || isHoliday(shifted)) ? "weekend" : "weekday";
    }
}
