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

    // line
    let line: String

    // current location
    let location: Int?

    // all stops
    let stops: [Stop]

    // line color
    func lineColor() -> Color {
        switch self.line {
        case "Local Weekday", "Local Weekend":
            return .gray

        case "Limited":
            return .cyan

        case "Express":
            return .red

        case "South County Connector":
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
