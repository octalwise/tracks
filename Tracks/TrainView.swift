import Foundation
import SwiftUI

struct TrainView: View {
    let train: Train

    let trains: [Train]
    let stations: [BothStations]

    @State var showPast = false

    @State var tick = Date()
    let refresh =
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = tick

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
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeOut(duration: 0.5)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        )
                    )
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
        .animation(
            .easeInOut(duration: 0.3),
            value: self.tick.hashValue ^ self.showPast.hashValue
        )
        .onAppear {
            if stopStations.count == 0 {
                self.showPast = true
            }
        }
        .onReceive(refresh) { self.tick = $0 }
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
                    past: stop.expected < Date()
                )
            }
    }
}
