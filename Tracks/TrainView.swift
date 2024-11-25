import Foundation
import SwiftUI

// individual train view
struct TrainView: View {
    // train
    let train: Train

    let trains:   [Train]
    let stations: [BothStations]

    @State var showPast = false

    var body: some View {
        let stopStations =
            self.stopStations().filter { self.showPast || $0.3 }

        ScrollView {
            HStack {
                // toggle past stops
                Toggle(isOn: self.$showPast) {
                    Text("Show Past Stops")
                }.toggleStyle(CheckboxStyle())

                Spacer()

                Text(self.train.route)
                    .foregroundStyle(self.train.routeColor())
                    .padding(.leading, 15)
                    .lineLimit(1)
            }.padding(15)

            Grid {
                ForEach(
                    Array(stopStations.enumerated()),
                    id: \.1.0.self
                ) { index, data in
                    if index > 0 {
                        Divider()
                    }

                    GridRow {
                        HStack {
                            // stop station
                            NavigationLink {
                                StationView(
                                    station:  data.1,
                                    trains:   self.trains,
                                    stations: self.stations
                                )
                            } label: {
                                Text(data.1.name).lineLimit(1)
                            }

                            Spacer()
                        }.gridColumnAlignment(.leading)

                        HStack {
                            if data.2 >= 1 {
                                // delay duration
                                Text(String(
                                    format: "+%.0f",
                                    data.0.scheduled.distance(to: data.0.expected) / 60
                                ))
                                .foregroundStyle(.red)
                                .padding(.trailing, 10)
                            }

                            // arrival time
                            Text(
                                data.0.expected
                                    .formatted(date: .omitted, time: .shortened)
                            ).monospacedDigit()
                        }.gridColumnAlignment(.trailing)
                    }
                    .padding([.leading, .trailing], 15)
                    .opacity(!data.3 ? 0.6 : 1.0)
                }

                if stopStations.count == 1 {
                    // expand grid width
                    Divider().opacity(0)
                }
            }.padding(.bottom, 15)
        }.navigationTitle(
            "Train \(self.train.id)\(!self.train.live ? "*" : "")"
        )
    }

    // get stops with stations
    func stopStations() -> [(Stop, BothStations, Double, Bool)] {
        self.train
            .stops
            .filter {
                // hide current stop
                self.train.location == nil || $0.station != self.train.location
            }
            .sorted {
                // sort by expected stop time
                $0.expected < $1.expected
            }
            .map { stop in
                (
                    // train stop
                    stop,

                    // stop station
                    stations.first {
                        $0.north.id == stop.station || $0.south.id == stop.station
                    }!,

                    // delay time
                    stop.scheduled.distance(to: stop.expected) / 60,

                    // check if delayed
                    stop.expected > Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
    }
}
