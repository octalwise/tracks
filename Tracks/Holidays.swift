import Foundation
import SwiftSoup

struct Holidays {
    var holidays: [(day: Int, month: Int)]

    init(html: String) {
        self.holidays = []

        do {
            let doc = try SwiftSoup.parse(html)

            for row in try doc.select("table.holiday-service-schedule tbody tr") {
                let vals = try row.select("td")

                if try vals.get(2).text() != "Weekend Schedule*" {
                    continue
                }

                let formatter = DateFormatter()

                formatter.dateFormat = "MMMM d"
                formatter.timeZone = TimeZone(abbreviation: "PST")

                guard let time = formatter.date(from: try vals.get(1).text()) else {
                    throw FormatError.formatError("Invalid time format in Caltrain data.")
                }

                let comps = Calendar.current.dateComponents([.day, .month], from: time)

                self.holidays.append((day: comps.day!, month: comps.month!))
            }
        } catch {
            self.holidays = []
        }
    }

    func isHoliday(_ date: Date) -> Bool {
        let comps = Calendar.current.dateComponents([.day, .month], from: date)
        return self.holidays.contains { $0.day == comps.day! && $0.month == comps.month! }
    }

    func service() -> String {
        let shifted = Calendar.current.date(byAdding: .hour, value: -4, to: Date())!

        let isWeekend = Calendar.current.isDateInWeekend(shifted)
        return (isWeekend || self.isHoliday(shifted)) ? "weekend" : "weekday";
    }
}
