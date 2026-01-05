import Foundation
import SwiftSoup

struct ScheduledTrain {
    let id: Int
    let direction: String
    let route: String
    let service: String
}

struct ScheduledStop {
    let station: Int
    let time: Date
    let train: Int
}

struct Scheduled {
    var trains: [ScheduledTrain]
    var stops: [ScheduledStop]

    init(html: String, holidays: Holidays) {
        let shifted = Calendar.current.date(byAdding: .hour, value: -5, to: Date())!

        self.trains = []
        self.stops = []

        do {
            let doc = try SwiftSoup.parse(html)

            for table in try doc.select("table.caltrain_schedule tbody") {
                let direction =
                    try table.parent()!.attr("data-direction") == "northbound" ? "N" : "S"

                for header in try table.select(
                    "tr:first-child td.schedule-trip-header"
                ) {
                    let train = Int(try header.attr("data-trip-id"))!
                    let fullRoute = try header.attr("data-route-id")
                    let service = try header.attr("data-service-type")

                    let isLocal = fullRoute == "Local Weekday" || fullRoute == "Local Weekend"
                    let route = isLocal ? "Local" : fullRoute

                    self.trains.append(
                        ScheduledTrain(
                            id: train,
                            direction: direction,
                            route: route,
                            service: service
                        )
                    )
                }

                for row in try table.select("tr[data-stop-id]") {
                    let stop = Int(try row.attr("data-stop-id"))!

                    for timepoint in try row.select("td.timepoint") {
                        if try timepoint.text() == "--" {
                            continue
                        }

                        let train = Int(try timepoint.attr("data-trip-id"))!

                        let formatter = DateFormatter()

                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
                        formatter.dateFormat = "h:mma"

                        guard let time = formatter.date(from: try timepoint.text()) else {
                            throw FormatError.formatError("Invalid time format in Caltrain data.")
                        }

                        self.stops.append(
                            ScheduledStop(
                                station: stop,
                                time: time,
                                train: train
                            )
                        )
                    }
                }
            }
        } catch {
            self.trains = []
            self.stops = []
        }
    }

    func fetch() -> [Train] {
        let now = Date()

        let stops =
            self.stops.map { stop in
                let calendar = Calendar.current

                var components =
                    calendar.dateComponents([.hour, .minute, .second], from: stop.time)

                let nowComponents =
                    calendar.dateComponents([.year, .month, .day, .hour], from: now)

                components.year = nowComponents.year
                components.month = nowComponents.month
                components.day = nowComponents.day

                var time = calendar.date(from: components)!

                // previous day
                if nowComponents.hour! <= 4 && components.hour! >= 4 {
                    time = calendar.date(byAdding: .day, value: -1, to: time)!
                }

                // next day
                if nowComponents.hour! >= 4 && components.hour! < 4 {
                    time = calendar.date(byAdding: .day, value: 1, to: time)!
                }

                return ScheduledStop(
                    station: stop.station,
                    time: time,
                    train: stop.train
                )
            }

        return self.trains.map { train in
            let trainStops =
                stops
                    .filter { $0.train == train.id }
                    .sorted { $0.time < $1.time }

            let times = trainStops.map { $0.time }

            let location =
                times.min()! <= now && times.max()! >= now
                    ? trainStops.last { $0.time <= now }!.station
                    : nil

            return Train(
                id: train.id,
                live: false,

                direction: train.direction,
                route: train.route,
                service: train.service,

                location: location,
                stops: trainStops.map {
                    Stop(
                        station: $0.station,
                        scheduled: $0.time,
                        expected: $0.time
                    )
                }
            )
        }
    }
}
