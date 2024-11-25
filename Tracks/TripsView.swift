import Foundation
import SwiftUI

// trips view
struct TripsView: View {
    let stations: [BothStations]
    let trains:   [Train]

    // from station
    @State var from: BothStations

    // to station
    @State var to: BothStations

    // show past trains
    @State var showPast = false

    var body: some View {
        let trainsStops =
            self.trainsStops().filter { self.showPast || $0.3 }

        HStack {
            // from station
            Menu {
                Picker("From", selection: self.$from) {
                    ForEach(self.stations, id: \.self) { station in
                        Text(station.name)
                    }
                }
            } label: {
                Text(self.from.name)
                    .lineLimit(1)
                    .padding(.trailing, -3)

                Image(systemName: "chevron.up.chevron.down")
            }

            // flip route
            Button(action: {
                withAnimation(.none) {
                    (self.from, self.to) = (self.to, self.from)
                }
            }) {
                Image(systemName: "arrow.right.arrow.left")
            }.padding([.leading, .trailing], 5)

            // to station
            Menu {
                Picker("To", selection: self.$to) {
                    ForEach(self.stations, id: \.self) { station in
                        Text(station.name)
                    }
                }
            } label: {
                Text(self.to.name)
                    .lineLimit(1)
                    .padding(.trailing, -3)

                Image(systemName: "chevron.up.chevron.down")
            }
        }
        .padding(.top, 10)
        .padding([.leading, .trailing], 15)

        HStack {
            // toggle past trains
            Toggle(isOn: self.$showPast) {
                Text("Show Past Trains")
            }.toggleStyle(CheckboxStyle())

            Spacer()
        }.padding(15)

        Grid {
            ForEach(
                Array(trainsStops.enumerated()),
                id: \.1.0
            ) { index, data in
                if index > 0 {
                    Divider()
                }

                GridRow {
                    // trip train
                    NavigationLink {
                        TrainView(
                            train:    data.0,
                            trains:   self.trains,
                            stations: self.stations
                        )
                    } label: {
                        HStack {
                            Image(systemName: "tram.fill")
                                .foregroundStyle(data.0.routeColor())

                            Text(String(data.0.id))
                        }
                    }.gridColumnAlignment(.leading)

                    // start time
                    Text(data.1.expected.formatted(date: .omitted, time: .shortened))
                        .monospacedDigit()
                        .gridColumnAlignment(.trailing)

                    // end time
                    Text(data.2.expected.formatted(date: .omitted, time: .shortened))
                        .monospacedDigit()
                        .gridColumnAlignment(.trailing)
                }
                .padding([.leading, .trailing], 15)
                .opacity(!data.3 ? 0.6 : 1.0)
            }

            if trainsStops.count == 1 {
                // expand grid width
                Divider().opacity(0)
            }
        }.padding(.bottom, 15)
    }

    // get trains with stops
    func trainsStops() -> [(Train, Stop, Stop, Bool)] {
        self.trains
            .map { train in
                (
                    // train
                    train,

                    // stop at from station
                    train.stops.first {
                        $0.station == self.from.north.id || $0.station == self.from.south.id
                    },

                    // stop at to station
                    train.stops.first {
                        $0.station == self.to.north.id || $0.station == self.to.south.id
                    }
                )
            }
            .filter {
                // filter trains with stops and from stop is before to stop
                $0.1 != nil && $0.2 != nil &&
                    $0.0.stops.firstIndex(of: $0.1!)! < $0.0.stops.firstIndex(of: $0.2!)!
            }
            .map {
                (
                    // train
                    $0.0,

                    // from stop
                    $0.1!,

                    // to stop
                    $0.2!,

                    // check if delayed
                    $0.1!.expected > Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
            .sorted {
                // sort by expected stop time
                $0.1.expected < $1.1.expected
            }
    }
}
