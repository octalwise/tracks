import Foundation
import SwiftSoup

// scheduled train
struct ScheduledTrain {
    let id:        Int
    let direction: String
    let route:     String
}

// scheduled stop
struct ScheduledStop {
    let station: Int
    var time:    Date
    let train:   Int
}

// error handling
enum ScheduledError: Error {
    case formatError(String)
}

// scheduled trains fetcher
struct Scheduled {
    var trains: [ScheduledTrain]
    var stops:  [ScheduledStop]

    // fetch scheduled
    init(html: String) {
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        let dayType   = isWeekend ? "weekend" : "weekday"

        self.trains = []
        self.stops  = []

        do {
            // parse html
            let doc = try SwiftSoup.parse(html)

            for table in try doc.select("table.caltrain_schedule tbody") {
                let direction =
                    try table.parent()!.attr("data-direction") == "northbound" ? "N" : "S"

                // scheduled trains
                for header in try table.select(
                    "tr:first-child td.schedule-trip-header[data-service-type=\(dayType)]"
                ) {
                    let train = Int(try header.attr("data-trip-id"))!
                    let fullRoute = try header.attr("data-route-id")

                    // remove local suffix
                    let isLocal = fullRoute == "Local Weekday" || fullRoute == "Local Weekend"
                    let route   = isLocal ? "Local" : fullRoute

                    // add scheduled train
                    self.trains.append(
                        ScheduledTrain(
                            id: train,
                            direction: direction,
                            route: route
                        )
                    )
                }

                // scheduled stops
                for row in try table.select("tr[data-stop-id]") {
                    let stop = Int(try row.attr("data-stop-id"))!

                    for timepoint in try row.select("td.timepoint") {
                        if try timepoint.text() == "--" {
                            continue
                        }

                        let train = Int(try timepoint.attr("data-trip-id"))!

                        let formatter = DateFormatter()

                        formatter.dateFormat = "hh:mma"
                        formatter.timeZone   = TimeZone(abbreviation: "PST")

                        // guard invalid times
                        guard let time = formatter.date(from: try timepoint.text()) else {
                            throw ScheduledError.formatError("Invalid time format in Caltrain data.")
                        }

                        // add scheduled stop
                        self.stops.append(
                            ScheduledStop(
                                station: stop,
                                time:    time,
                                train:   train
                            )
                        )
                    }
                }
            }
        } catch {
            self.trains = []
            self.stops  = []
        }
    }

    // fetch trains
    func fetchScheduled() -> [Train] {
        let now = Date()

        let stops =
            self.stops.map { stop in
                let calendar = Calendar.current

                var components =
                    calendar.dateComponents([.hour, .minute, .second], from: stop.time)

                let nowComponents =
                    calendar.dateComponents([.year, .month, .day, .hour], from: now)

                components.year  = nowComponents.year
                components.month = nowComponents.month
                components.day   = nowComponents.day

                var time = calendar.date(from: components)!

                // previous day
                if nowComponents.hour! >= 4 && components.hour! < 4 {
                    time = calendar.date(byAdding: .day, value: 1, to: time)!
                }

                // next day
                if nowComponents.hour! <= 4 && components.hour! >= 4 {
                    time = calendar.date(byAdding: .day, value: -1, to: time)!
                }

                return ScheduledStop(
                    station: stop.station,
                    time:    time,
                    train:   stop.train
                )
            }

        return self.trains.map { train in
            let trainStops = stops.filter { $0.train == train.id }

            let times = trainStops.map { $0.time }
            var location: Int? = nil

            // find location
            if times.min()! <= now && times.max()! >= now {
                let stop =
                    trainStops
                        .sorted { $0.time > $1.time }
                        .first  { $0.time <= now }

                location = stop!.station
            }

            // create train
            return Train(
                id:   train.id,
                live: false,

                direction: train.direction,
                route:     train.route,
                location:  location,

                stops: trainStops.map {
                    Stop(
                        station:   $0.station,
                        scheduled: $0.time,
                        expected:  $0.time
                    )
                }
            )
        }
    }
}
