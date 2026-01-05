import Foundation
import SwiftUI

struct StationsView: View {
    let trains: [Train]
    let stations: [BothStations]

    let altService: Bool

    @State var tick = Date()
    let refresh =
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = tick

        let stationTrains = self.stationTrains()

        Grid {
            ForEach(
                Array(stationTrains.enumerated()),
                id: \.1.station.self
            ) { index, data in
                let (station, south, north) = data

                HStack {
                    if south != nil {
                        // southbound train
                        NavigationLink {
                            TrainView(
                                train: south!,
                                trains: self.trains,
                                stations: self.stations,
                                altService: self.altService
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .applyForeground(color: south!.routeColor())
                                .frame(height: 22)
                        }
                        .applyButtonStyle(color: south!.routeColor())
                        .gridColumnAlignment(.leading)
                        .opacity(altService ? 0.4 : 1.0)
                        .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "chevron.down")
                            .gridColumnAlignment(.leading)
                            .frame(width: 22, height: 22)
                    }

                    Spacer()

                    // station text
                    NavigationLink {
                        StationView(
                            station: station,
                            trains: self.trains,
                            stations: self.stations,
                            altService: self.altService
                        )
                    } label: {
                        Text(station.name).lineLimit(1)
                    }

                    Spacer()

                    if north != nil {
                        // northbound train
                        NavigationLink {
                            TrainView(
                                train: north!,
                                trains: self.trains,
                                stations: self.stations,
                                altService: self.altService
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .applyForeground(color: north!.routeColor())
                                .frame(height: 22)
                                .transition(.opacity)
                        }
                        .applyButtonStyle(color: north!.routeColor())
                        .gridColumnAlignment(.leading)
                        .opacity(self.altService ? 0.4 : 1.0)
                        .frame(width: 22, height: 22)
                    } else {
                        Image(systemName: "chevron.up")
                            .gridColumnAlignment(.leading)
                            .frame(width: 22, height: 22)
                            .transition(.opacity)
                    }
                }
                .padding([.leading, .trailing], 40)
                .padding(.bottom, 10)
            }

            // expand grid width
            Divider().opacity(0)
        }
        .padding([.top, .bottom], 15)
        .animation(
            .easeInOut(duration: 0.3),
            value: self.trains.hashValue ^ self.stations.hashValue
        )
        .onReceive(refresh) { self.tick = $0 }
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
