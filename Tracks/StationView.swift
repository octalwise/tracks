import Foundation
import SwiftUI

struct StationView: View {
    let station: BothStations

    let trains: [Train]
    let stations: [BothStations]

    let altService: Bool

    @State var direction = "N"

    @State var pastOverride: Bool? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let allTrains = stopTrains(now: context.date)
            let showPast = pastOverride ?? !allTrains.contains(where: { !$0.past })
            let stopTrains = allTrains.filter { showPast || !$0.past }

            ScrollView {
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
                        id: \.1.train.id
                    ) { index, data in
                        let (train, stop, delay, past) = data

                        if index > 0 {
                            Divider().padding(.bottom, 4)
                        }

                        GridRow {
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
                                    Text(String(
                                        format: "+%.0f",
                                        stop.scheduled.distance(to: stop.expected) / 60
                                    ))
                                    .foregroundStyle(.red)
                                    .padding(.trailing, 10)
                                }

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
                        Divider().opacity(0)
                    }
                }.padding(.bottom, 15)
            }
            .navigationTitle(station.name)
            .animation(.easeInOut(duration: 0.3), value: stopTrains.map(\.train.id))
            .animation(.easeInOut(duration: 0.3), value: stopTrains.map(\.past))
            .animation(.easeInOut(duration: 0.3), value: showPast)
        }
    }

    func stopTrains(now: Date) -> [(train: Train, stop: Stop, delay: Double, past: Bool)] {
        trains
            .map { train in
                (
                    train: train,
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
                    train: train,
                    stop: stop,
                    delay: stop.scheduled.distance(to: stop.expected) / 60,
                    past: stop.expected < now
                )
            }
    }
}
