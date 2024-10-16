import Foundation
import SwiftUI

// individual station view
struct StationView: View {
    // station
    let station: BothStations

    let trains:   [Train]
    let stations: [BothStations]

    // trains direction
    @State var direction: String = "N"

    // show past trains
    @State var showPast = false

    var body: some View {
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
                    Array(
                        self.stopTrains()
                            .filter { self.showPast || $0.2 }
                            .enumerated()
                    ),
                    id: \.1.0.self
                ) { index, data in
                    if index > 0 {
                        Divider()
                    }

                    GridRow {
                        // train
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

                                Text("Train \(data.0.id)")
                            }
                        }.gridColumnAlignment(.leading)

                        // arrival time
                        Text(
                            data.1.expected
                                .formatted(date: .omitted, time: .shortened)
                        ).gridColumnAlignment(.trailing)
                    }
                    .padding([.leading, .trailing], 15)
                    .opacity(!data.2 ? 0.6 : 1.0)
                }
            }.padding(.bottom, 15)
        }.navigationTitle(self.station.name)
    }

    // get trains with stop
    func stopTrains() -> [(Train, Stop, Bool)] {
        self.trains
            .map {
                ($0, $0.stops.first {
                    $0.station == station.north.id || $0.station == station.south.id
                })
            }
            .filter {
                $0.0.direction == direction && $0.1 != nil
            }
            .sorted {
                $0.1!.expected < $1.1!.expected
            }
            .map {
                (
                    $0.0,
                    $0.1!,
                    $0.1!.expected > Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
    }
}
