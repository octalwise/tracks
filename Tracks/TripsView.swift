import Foundation
import SwiftUI

struct TripsView: View {
    let stations: [BothStations]
    let trains: [Train]

    let altService: Bool

    @State var from: BothStations
    @State var to: BothStations

    @AppStorage("from") var fromID = -1
    @AppStorage("to") var toID = -1

    @State var pastOverride: Bool? = nil

    @State var tick = Date()
    let refresh =
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let _ = tick

        let showPast = pastOverride ?? !trainsStops().contains(where: { !$0.past })

        let trainsStops = trainsStops().filter { showPast || !$0.past }

        VStack {
            HStack {
                // from station
                Menu {
                    Picker("From", selection: $from) {
                        ForEach(stations, id: \.self) { station in
                            Text(station.name)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } label: {
                    HStack {
                        Text(from.name)
                            .lineLimit(1)
                            .padding(.trailing, -3)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }

                // flip route
                Button(action: {
                    withAnimation(.none) {
                        (from, to) = (to, from)
                    }
                }) {
                    Image(systemName: "arrow.right.arrow.left")
                }
                .padding([.leading, .trailing], 10)

                // to station
                Menu {
                    Picker("To", selection: $to) {
                        ForEach(stations, id: \.self) { station in
                            Text(station.name)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } label: {
                    HStack {
                        Text(to.name)
                            .lineLimit(1)
                            .padding(.trailing, -3)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .onChange(of: from) { val in
                fromID = val.north.id
            }
            .onChange(of: to) { val in
                toID = val.north.id
            }
            .onAppear {
                if fromID != -1 {
                    from = stations.first {
                        $0.contains(id: fromID)
                    }!
                }

                if toID != -1 {
                    to = stations.first {
                        $0.contains(id: toID)
                    }!
                }
            }
            .padding(.top, 10)
            .padding([.leading, .trailing], 20)

            HStack {
                // toggle past trains
                Toggle(
                    "Show Past Trains",
                    isOn: Binding(
                        get: { showPast },
                        set: { val in pastOverride = val }
                    )
                ).toggleStyle(CheckboxStyle())

                Spacer()
            }
            .padding(.top, 13)
            .padding(.bottom, 15)
            .padding([.leading, .trailing], 20)

            Grid {
                ForEach(
                    Array(trainsStops.enumerated()),
                    id: \.1.train.self
                ) { index, data in
                    let (train, from, to, past) = data

                    if index > 0 {
                        Divider().padding(.bottom, 4)
                    }

                    GridRow {
                        // trip train
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

                        // start time
                        Text(from.expected.formatTime())
                            .monospacedDigit()
                            .gridColumnAlignment(.trailing)

                        // end time
                        Text(to.expected.formatTime())
                            .monospacedDigit()
                            .gridColumnAlignment(.trailing)
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

                if trainsStops.count == 1 {
                    // expand grid width
                    Divider().opacity(0)
                }
            }.padding(.bottom, 15)
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: tick.hashValue ^ showPast.hashValue
        )
        .onReceive(refresh) { tick = $0 }
    }

    func trainsStops() -> [(train: Train, from: Stop, to: Stop, past: Bool)] {
        trains
            .map { train in
                (
                    // train
                    train: train,

                    // stop at from station
                    from: train.stops.first { from.contains(id: $0.station) },

                    // stop at to station
                    to: train.stops.first { to.contains(id: $0.station) }
                )
            }
            .filter { (train: Train, from: Stop?, to: Stop?) in
                from != nil && to != nil &&
                    train.stops.firstIndex(of: from!)! < train.stops.firstIndex(of: to!)!
            }
            .map { (train, from, to) in
                (
                    // train
                    train: train,

                    // from stop
                    from: from!,

                    // to stop
                    to: to!,

                    // check if past stop
                    past: from!.expected < Date()
                )
            }
            .sorted {
                $0.from.expected < $1.from.expected
            }
    }
}
