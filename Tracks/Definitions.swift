import Foundation
import SwiftUI

struct Train: Codable, Hashable {
    let id: Int
    let live: Bool

    let direction: String
    let route: String

    let location: Int?
    let stops: [Stop]

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

struct Stop: Codable, Hashable {
    let station: Int

    let scheduled: Date
    let expected: Date
}

struct Alert: Codable, Hashable {
    let header: String
    let description: String?
}

extension Date {
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

enum FormatError: Error {
    case formatError(String)
}
