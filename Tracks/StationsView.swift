import Foundation
import SwiftUI

struct StationsView: View {
    let trains: [Train]
    let stations: [BothStations]

    var body: some View {
        let stationTrains = self.stationTrains()

        Grid {
            ForEach(
                Array(stationTrains.enumerated()),
                id: \.1.station.self
            ) { index, data in
                let (station, south, north) = data

                if index > 0 {
                    Divider().padding(.bottom, 4)
                }

                GridRow {
                    if south != nil {
                        // southbound train
                        NavigationLink {
                            TrainView(
                                train: south!,
                                trains: self.trains,
                                stations: self.stations
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .foregroundStyle(south!.routeColor())
                        }.gridColumnAlignment(.leading)
                    } else {
                        Image(systemName: "chevron.down")
                            .gridColumnAlignment(.leading)
                    }

                    // station text
                    NavigationLink {
                        StationView(
                            station: station,
                            trains: self.trains,
                            stations: self.stations
                        )
                    } label: {
                        Text(station.name).lineLimit(1)
                    }

                    if north != nil {
                        // northbound train
                        NavigationLink {
                            TrainView(
                                train: north!,
                                trains: self.trains,
                                stations: self.stations
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .foregroundStyle(north!.routeColor())
                        }.gridColumnAlignment(.trailing)
                    } else {
                        Image(systemName: "chevron.up")
                            .gridColumnAlignment(.trailing)
                    }
                }.padding([.leading, .trailing], 20)
            }

            if stationTrains.count == 1 {
                // expand grid width
                Divider().opacity(0)
            }
        }.padding([.top, .bottom], 15)
    }

    func stationTrains() -> [(station: BothStations, south: Train?, north: Train?)] {
        self.stations
            .map { station in
                (
                    station: station,
                    south: trains.first { $0.id == station.south.train },
                    north: trains.first { $0.id == station.north.train }
                )
            }
    }
}
