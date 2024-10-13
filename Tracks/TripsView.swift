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
        HStack {
            // from station
            Menu {
                Picker("From", selection: $from) {
                    ForEach(self.stations, id: \.self) { station in
                        Text(station.name)
                    }
                }
            } label: {
                Text(from.name)
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
                Picker("To", selection: $to) {
                    ForEach(self.stations, id: \.self) { station in
                        Text(station.name)
                    }
                }
            } label: {
                Text(to.name)
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
                Array(
                    self.trainsStops()
                        .filter { self.showPast || $0.3 }
                        .enumerated()
                ),
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
                                .foregroundColor(data.0.routeColor())

                            Text(String(data.0.id))
                        }
                    }.gridColumnAlignment(.leading)

                    // start time
                    Text(data.1.expected.formatted(date: .omitted, time: .shortened))
                        .gridColumnAlignment(.trailing)

                    // end time
                    Text(data.2.expected.formatted(date: .omitted, time: .shortened))
                        .gridColumnAlignment(.trailing)
                }
                .padding([.leading, .trailing], 15)
                .opacity(!data.3 ? 0.6 : 1.0)
            }
        }
    }

    // get trains with stops
    func trainsStops() -> [(Train, Stop, Stop, Bool)] {
        self.trains
            .map {
                (
                    $0,
                    $0.stops.first {
                        $0.station == from.north.id || $0.station == from.south.id
                    },
                    $0.stops.first {
                        $0.station == to.north.id || $0.station == to.south.id
                    }
                )
            }
            .filter {
                $0.1 != nil && $0.2 != nil &&
                    $0.0.stops.firstIndex(of: $0.1!)! < $0.0.stops.firstIndex(of: $0.2!)!
            }
            .map {
                (
                    $0.0,
                    $0.1!,
                    $0.2!,
                    $0.1!.expected > Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
            .sorted {
                $0.1.expected < $1.1.expected
            }
    }
}
