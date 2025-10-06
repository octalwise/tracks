import Foundation
import SwiftUI

struct TrainView: View {
    let train: Train

    let trains: [Train]
    let stations: [BothStations]

    @State var showPast = false

    var body: some View {
        let stopStations =
            self.stopStations().filter { self.showPast || !$0.past }

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
            }
            .padding(.top, 10)
            .padding(.bottom, 15)
            .padding([.leading, .trailing], 20)

            Grid {
                ForEach(
                    Array(stopStations.enumerated()),
                    id: \.1.stop.self
                ) { index, data in
                    let (stop, station, delay, past) = data

                    if index > 0 {
                        Divider().padding(.bottom, 4)
                    }

                    GridRow {
                        HStack {
                            // stop station
                            NavigationLink {
                                StationView(
                                    station: station,
                                    trains: self.trains,
                                    stations: self.stations
                                )
                            } label: {
                                Text(station.name).lineLimit(1)
                            }

                            Spacer()
                        }.gridColumnAlignment(.leading)

                        HStack {
                            if delay >= 1 {
                                // delay duration
                                Text(String(
                                    format: "+%.0f",
                                    stop.scheduled.distance(to: stop.expected) / 60
                                ))
                                .foregroundStyle(.red)
                                .padding(.trailing, 10)
                            }

                            // arrival time
                            Text(stop.expected.formatTime())
                                .monospacedDigit()
                        }.gridColumnAlignment(.trailing)
                    }
                    .padding([.leading, .trailing], 20)
                    .opacity(past ? 0.6 : 1.0)
                }

                if stopStations.count == 1 {
                    // expand grid width
                    Divider().opacity(0)
                }
            }.padding(.bottom, 15)
        }
        .navigationTitle(
            "Train \(self.train.id)\(!self.train.live ? "*" : "")"
        )
        .onAppear {
            if stopStations.count == 0 {
                // show past if no future stops
                self.showPast = true
            }
        }
    }

    func stopStations() -> [(stop: Stop, station: BothStations, delay: Double, past: Bool)] {
        self.train
            .stops
            .sorted {
                $0.expected < $1.expected
            }
            .map { stop in
                (
                    // train stop
                    stop: stop,

                    // stop station
                    station: stations.first { $0.contains(id: stop.station) }!,

                    // delay time
                    delay: stop.scheduled.distance(to: stop.expected) / 60,

                    // check if past stop
                    past: stop.station == self.train.location
                        || stop.expected < Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
    }
}
