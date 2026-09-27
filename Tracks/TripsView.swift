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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let allStops = trainsStops(now: context.date)
            let showPast = pastOverride ?? !allStops.contains(where: { !$0.past })
            let trainsStops = allStops.filter { showPast || !$0.past }

            VStack {
                HStack {
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

                    Button(action: {
                        withAnimation(.none) {
                            (from, to) = (to, from)
                        }
                    }) {
                        Image(systemName: "arrow.right.arrow.left")
                    }
                    .padding([.leading, .trailing], 10)

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
                        id: \.1.train.id
                    ) { index, data in
                        let (train, from, to, past) = data

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

                            Text(from.expected.formatTime())
                                .monospacedDigit()
                                .gridColumnAlignment(.trailing)

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
                        Divider().opacity(0)
                    }
                }.padding(.bottom, 15)
            }
            .animation(.easeInOut(duration: 0.3), value: trainsStops.map(\.train.id))
            .animation(.easeInOut(duration: 0.3), value: trainsStops.map(\.past))
            .animation(.easeInOut(duration: 0.3), value: showPast)
        }
    }

    func trainsStops(now: Date) -> [(train: Train, from: Stop, to: Stop, past: Bool)] {
        trains
            .map { train in
                (
                    train: train,
                    from: train.stops.first { from.contains(id: $0.station) },
                    to: train.stops.first { to.contains(id: $0.station) }
                )
            }
            .filter { (train: Train, from: Stop?, to: Stop?) in
                from != nil && to != nil &&
                    train.stops.firstIndex(of: from!)! < train.stops.firstIndex(of: to!)!
            }
            .map { (train, from, to) in
                (
                    train: train,
                    from: from!,
                    to: to!,
                    past: from!.expected < now
                )
            }
            .sorted {
                $0.from.expected < $1.from.expected
            }
    }
}
