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

    var location: Int?
    var offset: Bool

    let stops: [Stop]

    init(id: Int, live: Bool, direction: String, route: String, service: String, stops: [Stop]) {
        self.id = id
        self.live = live
        self.direction = direction
        self.route = route
        self.service = service
        self.stops = stops
        self.location = nil
        self.offset = false
        refresh()
    }

    mutating func refresh() {
        let now = Date()

        if stops.first!.expected > now || stops.last!.expected <= now {
            location = nil
            offset = false
            return
        }

        let nextIdx = stops.firstIndex { $0.expected > now }!

        let nextStop = stops[nextIdx]
        let prevStop = stops[nextIdx - 1]

        let idx1 = STATIONS.firstIndex { $0.contains(id: prevStop.station) }!
        let idx2 = STATIONS.firstIndex { $0.contains(id: nextStop.station) }!

        if now >= nextStop.expected.addingTimeInterval(-20) {
            location = STATIONS[idx2].side(direction: direction)
            offset = false
        } else {
            let dt = nextStop.expected.timeIntervalSince(prevStop.expected)
            let mix = min(1, max(0, now.timeIntervalSince(prevStop.expected) / dt))

            let off = mix * Double(idx2 - idx1)
            let frac = off - trunc(off)

            location = STATIONS[idx1 + Int(off)].side(direction: direction)
            offset = abs(frac) > 0.25
        }
    }

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

func faded(_ color: Color) -> Color {
    return color.mix(with: Color(.systemBackground), by: 0.6)
}

extension View {
    @ViewBuilder
    func applyForeground(color: Color, fade: Bool) -> some View {
        if #available(iOS 26.0, *) {
            foregroundStyle(fade ? faded(Color.primary) : Color.primary)
        } else {
            foregroundStyle(fade ? faded(color) : color)
        }
    }

    @ViewBuilder
    func applyButtonStyle(color: Color, fade: Bool) -> some View {
        if #available(iOS 26.0, *) {
            self
                .buttonStyle(.glass)
                .glassEffect(.regular.tint((fade ? faded(color) : color).opacity(0.3)))
        } else {
            self
                .buttonStyle(.bordered)
                .buttonBorderShape(ButtonBorderShape.capsule)
                .background(Capsule().fill(.background))
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
