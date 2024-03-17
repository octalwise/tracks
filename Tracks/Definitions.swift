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
        case "L1":
            return .gray

        case "L3", "L4", "L5":
            return .yellow

        case "B7":
            return .red

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
