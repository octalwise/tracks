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
        ScrollView {
            HStack {
                // toggle past stops
                Toggle(isOn: self.$showPast) {
                    Text("Show Past Stops")
                }.toggleStyle(CheckboxStyle())

                Spacer()
            }.padding()

            Grid {
                ForEach(
                    Array(
                        self.stopStations()
                            .filter { self.showPast || $0.3 }
                            .enumerated()
                    ),
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
                                    station: data.1,
                                    trains: self.trains,
                                    stations: self.stations
                                )
                            } label: {
                                Text(data.1.name)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .gridColumnAlignment(.leading)
                        .gridCellColumns(data.2 >= 1 ? 1 : 2)

                        if data.2 >= 1 {
                            // delay duration
                            Text(String(
                                format: "+%.0f min",
                                data.0.scheduled.distance(to: data.0.expected) / 60
                            ))
                            .gridColumnAlignment(.trailing)
                            .foregroundColor(.red)
                        }

                        // arrival time
                        Text(data.0.expected.formatted(date: .omitted, time: .shortened))
                            .gridColumnAlignment(.trailing)
                    }
                    .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .opacity(!data.3 ? 0.6 : 1.0)
                }
            }
        }.navigationTitle(
            "Train \(train.id)\(!train.live ? "*" : "")"
        )
    }

    // get stops with stations
    func stopStations() -> [(Stop, BothStations, Double, Bool)] {
        self.train
            .stops
            .filter {
                train.location == nil || $0.station != train.location
            }
            .sorted {
                $0.expected < $1.expected
            }
            .map { stop in
                (
                    stop,
                    stations.first {
                        $0.north.id == stop.station || $0.south.id == stop.station
                    }!,
                    stop.scheduled.distance(to: stop.expected) / 60,
                    stop.expected > Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
    }
}
