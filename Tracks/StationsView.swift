import Foundation
import SwiftUI

// all stations view
struct StationsView: View {
    let trains:   [Train]
    let stations: [BothStations]

    var body: some View {
        Grid {
            ForEach(
                Array(self.stationTrains().enumerated()),
                id: \.1.0.self
            ) { index, data in
                if index > 0 {
                    Divider()
                }

                GridRow {
                    if data.1 != nil {
                        // northbound train
                        NavigationLink {
                            TrainView(
                                train: data.1!,
                                trains: self.trains,
                                stations: self.stations
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .foregroundColor(data.1!.lineColor())
                        }.gridColumnAlignment(.leading)
                    } else {
                        Image(systemName: "chevron.down")
                            .gridColumnAlignment(.leading)
                    }

                    // station text
                    NavigationLink {
                        StationView(
                            station: data.0,
                            trains: self.trains,
                            stations: self.stations
                        )
                    } label: {
                        Text(data.0.name).lineLimit(1)
                    }

                    if data.2 != nil {
                        // southbound train
                        NavigationLink {
                            TrainView(
                                train: data.2!,
                                trains: self.trains,
                                stations: self.stations
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .foregroundColor(data.2!.lineColor())
                        }.gridColumnAlignment(.trailing)
                    } else {
                        Image(systemName: "chevron.up")
                            .gridColumnAlignment(.trailing)
                    }
                }.padding([.leading, .trailing], 20)
            }
        }.padding(.top, 10)
    }

    // get trains for station
    func stationTrains() -> [(BothStations, Train?, Train?)] {
        self.stations
            .map { station in
                (
                    station,
                    trains.first { $0.id == station.south.train },
                    trains.first { $0.id == station.north.train }
                )
            }
    }
}
