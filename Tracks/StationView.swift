import Foundation
import SwiftUI

struct StationView: View {
    let station: BothStations

    let trains: [Train]
    let stations: [BothStations]

    let altService: Bool

    @State var direction = "N"

    @State var pastOverride: Bool? = nil

    @State var tick = Date()
    let refresh =
        Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = tick

        let showPast = pastOverride ?? !stopTrains().contains(where: { !$0.past })

        let stopTrains = stopTrains().filter { showPast || !$0.past }

        ScrollView {
            // select direction
            Picker("Direction", selection: $direction) {
                Text("Northbound").tag("N")
                Text("Southbound").tag("S")
            }
            .pickerStyle(.segmented)
            .padding(.top, 15)
            .padding([.leading, .trailing], 20)

            HStack {
                Toggle(
                    "Show Past Trains",
                    isOn: Binding(
                        get: { showPast },
                        set: { pastOverride = $0 }
                    )
                ).toggleStyle(CheckboxStyle())

                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 15)
            .padding([.leading, .trailing], 20)

            Grid {
                ForEach(
                    Array(stopTrains.enumerated()),
                    id: \.1.train.self
                ) { index, data in
                    let (train, stop, delay, past) = data

                    if index > 0 {
                        Divider().padding(.bottom, 4)
                    }

                    GridRow {
                        // train
                        NavigationLink {
                            TrainView(
                                train: train,
                                trains: trains,
                                stations: stations,
                                altService: altService
                            )
                        } label: {
                            HStack {
                                Image(systemName: "tram.fill")
                                    .foregroundStyle(train.routeColor())

                                Text(String(train.id))
                            }
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
                    .opacity(past || altService ? 0.6 : 1.0)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeOut(duration: 0.5)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        )
                    )
                }

                if stopTrains.count == 1 {
                    // expand grid width
                    Divider().opacity(0)
                }
            }.padding(.bottom, 15)
        }
        .navigationTitle(station.name)
        .animation(
            .easeInOut(duration: 0.3),
            value: tick.hashValue ^ showPast.hashValue
        )
        .onReceive(refresh) { tick = $0 }
    }

    func stopTrains() -> [(train: Train, stop: Stop, delay: Double, past: Bool)] {
        trains
            .map { train in
                (
                    // train
                    train: train,

                    // train stop in station
                    stop: train.stops.first {
                        station.contains(id: $0.station)
                    }
                )
            }
            .filter { (train, stop) in
                train.direction == direction && stop != nil
            }
            .sorted {
                $0.stop!.expected < $1.stop!.expected
            }
            .map { (train, stop) in
                let stop = stop!

                return (
                    // train
                    train: train,

                    // station stop
                    stop: stop,

                    // delay time
                    delay: stop.scheduled.distance(to: stop.expected) / 60,

                    // check if past stop
                    past: stop.expected < Date()
                )
            }
    }
}
