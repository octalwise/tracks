import Foundation
import SwiftUI

struct StationsView: View {
    let trains: [Train]
    let stations: [BothStations]

    let altService: Bool

    var body: some View {
        let stationTrains = stationTrains()

        Grid {
            ForEach(
                Array(stationTrains.enumerated()),
                id: \.1.station.self
            ) { index, data in
                let (station, south, north) = data

                HStack {
                    ZStack {
                        Image(systemName: "chevron.down")
                            .frame(width: 22, height: 22)

                        if south != nil {
                            NavigationLink {
                                TrainView(
                                    train: south!,
                                    trains: trains,
                                    stations: stations,
                                    altService: altService
                                )
                            } label: {
                                Image(systemName: "tram.fill")
                                    .applyForeground(color: south!.routeColor(), fade: altService)
                                    .frame(height: 22)
                                    .transition(.opacity)
                            }
                            .applyButtonStyle(color: south!.routeColor(), fade: altService)
                            .frame(width: 22, height: 22)
                            .offset(y: south!.offset ? 18 : 0)
                        }
                    }

                    Spacer()

                    NavigationLink {
                        StationView(
                            station: station,
                            trains: trains,
                            stations: stations,
                            altService: altService
                        )
                    } label: {
                        Text(station.name).lineLimit(1)
                    }

                    Spacer()

                    ZStack {
                        Image(systemName: "chevron.up")
                            .frame(width: 22, height: 22)

                        if north != nil {
                            NavigationLink {
                                TrainView(
                                    train: north!,
                                    trains: trains,
                                    stations: stations,
                                    altService: altService
                                )
                            } label: {
                                Image(systemName: "tram.fill")
                                    .applyForeground(color: north!.routeColor(), fade: altService)
                                    .frame(height: 22)
                                    .transition(.opacity)
                            }
                            .applyButtonStyle(color: north!.routeColor(), fade: altService)
                            .frame(width: 22, height: 22)
                            .offset(y: north!.offset ? -18 : 0)
                        }
                    }
                }
                .padding([.leading, .trailing], 40)
                .padding(.bottom, 10)
                .zIndex(south?.offset == true || north?.offset == true ? 1 : 0)
            }

            Divider().opacity(0)
        }
        .padding([.top, .bottom], 15)
        .animation(.easeInOut(duration: 0.3), value: trains)
        .animation(.easeInOut(duration: 0.3), value: stations)
    }

    func stationTrains() -> [(station: BothStations, south: Train?, north: Train?)] {
        stations
            .map { station in
                (
                    station: station,
                    south: trains.first { $0.id == station.south.train },
                    north: trains.first { $0.id == station.north.train }
                )
            }
    }
}
