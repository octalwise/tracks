import Foundation
import SwiftUI

let laTz = TimeZone(identifier: "America/Los_Angeles")!

let laCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = laTz
    return cal
}()

struct Train: Codable, Hashable {
    let id: Int
    let live: Bool

    let direction: String
    let route: String
    let service: String

    let location: Int?
    let offset: Bool

    let stops: [Stop]

    func routeColor() -> Color {
        switch route {
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

extension View {
    @ViewBuilder
    func applyForeground(color: Color) -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            foregroundStyle(color)
        }
    }

    @ViewBuilder
    func applyButtonStyle(color: Color) -> some View {
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.glass)
                .glassEffect(.regular.tint(color.opacity(0.3)))
        } else {
            self
                .buttonStyle(.bordered)
                .buttonBorderShape(ButtonBorderShape.capsule)
        }
    }
}

extension Date {
    func formatTime() -> String {
        let is24h = DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: .current
        )?.contains("H") ?? false

        var base = Date.FormatStyle().minute(.twoDigits)
        base.timeZone = laTz

        let format =
            is24h
                ? base.hour(.twoDigits(amPM: .omitted))
                : base.hour(.defaultDigits(amPM: .abbreviated))

        return formatted(format)
    }
}

enum FormatError: Error {
    case formatError(String)
}
