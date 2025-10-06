import Foundation
import SwiftUI

// trips view
struct TripsView: View {
    let stations: [BothStations]
    let trains: [Train]

    // from station
    @State var from: BothStations

    // to station
    @State var to: BothStations

    // show past trains
    @State var showPast = false

    var body: some View {
        let trainsStops =
            self.trainsStops().filter { self.showPast || !$0.past }

        VStack {
            HStack {
                // from station
                Menu {
                    Picker("From", selection: self.$from) {
                        ForEach(self.stations, id: \.self) { station in
                            Text(station.name)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } label: {
                    HStack {
                        Text(self.from.name)
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
                        (self.from, self.to) = (self.to, self.from)
                    }
                }) {
                    Image(systemName: "arrow.right.arrow.left")
                }
                .padding([.leading, .trailing], 10)

                // to station
                Menu {
                    Picker("To", selection: self.$to) {
                        ForEach(self.stations, id: \.self) { station in
                            Text(station.name)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } label: {
                    HStack {
                        Text(self.to.name)
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
            .padding(.top, 10)
            .padding([.leading, .trailing], 20)

            HStack {
                // toggle past trains
                Toggle(isOn: self.$showPast) {
                    Text("Show Past Trains")
                }.toggleStyle(CheckboxStyle())

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
                                trains: self.trains,
                                stations: self.stations
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
                    .opacity(past ? 0.6 : 1.0)
                }

                if trainsStops.count == 1 {
                    // expand grid width
                    Divider().opacity(0)
                }
            }.padding(.bottom, 15)
        }.onAppear {
            if trainsStops.count == 0 {
                // show past if no future stops
                self.showPast = true
            }
        }
    }

    // get trains with stops
    func trainsStops() -> [(train: Train, from: Stop, to: Stop, past: Bool)] {
        self.trains
            .map { train in
                (
                    // train
                    train: train,

                    // stop at from station
                    from: train.stops.first { self.from.contains(id: $0.station) },

                    // stop at to station
                    to: train.stops.first { self.to.contains(id: $0.station) }
                )
            }
            .filter { (train: Train, from: Stop?, to: Stop?) in
                // filter trains with stops and from stop is before to stop
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
                    past: from!.expected < Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
                )
            }
            .sorted {
                // sort by expected stop time
                $0.from.expected < $1.from.expected
            }
    }
}
