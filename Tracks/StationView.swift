import Foundation
import SwiftUI

// individual station view
struct StationView: View {
    // station
    let station: BothStations

    let trains:   [Train]
    let stations: [BothStations]

    // trains direction
    @State var direction = "N"

    // show past trains
    @State var showPast = false

    var body: some View {
        let stopTrains =
            self.stopTrains().filter { self.showPast || !$0.past }

        ScrollView {
            // select direction
            Picker("Direction", selection: self.$direction) {
                Text("Northbound").tag("N")
                Text("Southbound").tag("S")
            }
            .pickerStyle(.segmented)
            .padding(.top, 15)
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
                    Array(stopTrains.enumerated()),
                    id: \.1.train.self
                ) { index, data in
                    let (train, stop, past) = data

                    if index > 0 {
                        Divider()
                    }

                    GridRow {
                        // train
                        NavigationLink {
                            TrainView(
                                train:    train,
                                trains:   self.trains,
                                stations: self.stations
                            )
                        } label: {
                            HStack {
                                Image(systemName: "tram.fill")
                                    .foregroundStyle(train.routeColor())

                                Text("Train \(train.id)")
                            }
                        }.gridColumnAlignment(.leading)

                        // arrival time
                        Text(
                            stop.expected
                                .formatted(date: .omitted, time: .shortened)
                        )
                        .monospacedDigit()
                        .gridColumnAlignment(.trailing)
                    }
                    .padding([.leading, .trailing], 15)
                    .opacity(past ? 0.6 : 1.0)
                }

                if stopTrains.count == 1 {
                    // expand grid width
                    Divider().opacity(0)
                }
            }.padding(.bottom, 15)
        }.navigationTitle(self.station.name)
    }

    // get trains with stop
    func stopTrains() -> [(train: Train, stop: Stop, past: Bool)] {
        self.trains
            .map { train in
                (
                    // train
                    train: train,

                    // train stop in station
                    stop: train.stops.first {
                        self.station.contains(id: $0.station)
                    }
                )
            }
            .filter { (train, stop) in
                // filter trains going in direction and stopping at station
                train.direction == direction && stop != nil
            }
            .sorted {
                // sort by expected stop time
                $0.stop!.expected < $1.stop!.expected
            }
            .map { (train, stop) in
                (
                    // train
                    train: train,

                    // station stop
                    stop: stop!,

                    // check if past stop
                    stop!.expected < Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
    }
}
