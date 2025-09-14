import Foundation
import SwiftUI

// train
struct Train: Codable, Hashable {
    // train id
    let id: Int

    // is live
    let live: Bool

    // direction
    let direction: String

    // route
    let route: String

    // current location
    let location: Int?

    // all stops
    let stops: [Stop]

    // route color
    func routeColor() -> Color {
        switch self.route {
        case "Local":
            return .gray

        case "Limited":
            return .cyan

        case "Express":
            return .red

        case "South County":
            return .yellow

        default:
            return .gray
        }
    }
}

// stop
struct Stop: Codable, Hashable {
    // station id
    let station: Int

    // scheduled time
    let scheduled: Date

    // expected time
    let expected: Date
}

// alert
struct Alert: Codable, Hashable {
    // header
    let header: String

    // optional description
    let description: String?
}

extension Date {
    // time format handling leading zeroes
    func formatTime() -> String {
        let is24h = DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: .current
        )?.contains("H") ?? false

        let base = Date.FormatStyle().minute(.twoDigits)

        let format =
            is24h
                ? base.hour(.twoDigits(amPM: .omitted))
                : base.hour(.defaultDigits(amPM: .abbreviated))

        return self.formatted(format)
    }
}
