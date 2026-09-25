import Foundation
import SwiftUI

struct StationsView: View {
    let trains: [Train]
    let stations: [BothStations]

    let altService: Bool

    @State var tick = Date()
    let refresh =
        Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = tick

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
                            // southbound train
                            NavigationLink {
                                TrainView(
                                    train: south!,
                                    trains: trains,
                                    stations: stations,
                                    altService: altService
                                )
                            } label: {
                                Image(systemName: "tram.fill")
                                    .applyForeground(color: south!.routeColor())
                                    .frame(height: 22)
                                    .transition(.opacity)
                            }
                            .applyButtonStyle(color: south!.routeColor())
                            .opacity(altService ? 0.4 : 1.0)
                            .frame(width: 22, height: 22)
                            .offset(y: south!.offset ? 20 : 0)
                        }
                    }

                    Spacer()

                    // station text
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
                            // northbound train
                            NavigationLink {
                                TrainView(
                                    train: north!,
                                    trains: trains,
                                    stations: stations,
                                    altService: altService
                                )
                            } label: {
                                Image(systemName: "tram.fill")
                                    .applyForeground(color: north!.routeColor())
                                    .frame(height: 22)
                                    .transition(.opacity)
                            }
                            .applyButtonStyle(color: north!.routeColor())
                            .opacity(altService ? 0.4 : 1.0)
                            .frame(width: 22, height: 22)
                            .offset(y: north!.offset ? -20 : 0)
                        }
                    }
                }
                .padding([.leading, .trailing], 40)
                .padding(.bottom, 10)
                .zIndex(south?.offset == true || north?.offset == true ? 1 : 0)
            }

            // expand grid width
            Divider().opacity(0)
        }
        .padding([.top, .bottom], 15)
        .animation(
            .easeInOut(duration: 0.3),
            value: trains.hashValue ^ stations.hashValue
        )
        .onReceive(refresh) { tick = $0 }
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
