import Foundation
import SwiftUI

struct ContentView: View {
    @State var trains: [Train]? = nil
    @State var alerts: [Alert]? = nil
    @State var stations: [BothStations]? = nil

    @State var lastUpdate: Date? = nil

    let scheduled: Scheduled? = nil
    let holidays: Holidays? = nil

    // every 90 seconds
    let trainsTimer =
        Timer.publish(every: 90, on: .main, in: .common).autoconnect()

    // every 180 seconds
    let alertsTimer =
        Timer.publish(every: 180, on: .main, in: .common).autoconnect()

    // every 5am
    let scheduledTimer =
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            // all stations view
            NavigationStack {
                ScrollView {
                    if self.stations != nil && self.trains != nil {
                        StationsView(trains: self.trains!, stations: self.stations!)
                    } else {
                        ProgressView() {
                            Text("Loading Trains")
                        }.padding(15)
                    }
                }.navigationTitle("Stations")
            }
            .tabItem {
                Label("Stations", systemImage: "house.fill")
            }

            // trips view
            NavigationStack {
                ScrollView {
                    if self.stations != nil && self.trains != nil {
                        TripsView(
                            stations: self.stations!,
                            trains: self.trains!,

                            from: self.stations!.first {
                                $0.name == "Palo Alto"
                            }!,
                            to: self.stations!.first {
                                $0.name == "San Mateo"
                            }!
                        )
                    } else {
                        ProgressView() {
                            Text("Loading Trains")
                        }.padding(15)
                    }
                }.navigationTitle("Trips")
            }
            .tabItem {
                Label("Trips", systemImage: "map.fill")
            }

            // alerts view
            NavigationStack {
                ScrollView {
                    if self.alerts != nil {
                        AlertsView(alerts: self.alerts!)
                    } else {
                        ProgressView() {
                            Text("Loading Alerts")
                        }.padding(15)
                    }
                }.navigationTitle("Alerts")
            }
            .tabItem {
                Label("Alerts", systemImage: "exclamationmark.triangle.fill")
            }
        }
        .onAppear {
            self.fetchTrains()
            self.fetchAlerts()
        }
        .refreshable {
            self.fetchTrains()
            self.fetchAlerts()
        }
        .onReceive(self.trainsTimer) { _ in
            // every 90 seconds
            self.fetchTrains()
        }
        .onReceive(self.alertsTimer) { _ in
            // every 180 seconds
            self.fetchAlerts()
        }
        .onReceive(self.scheduledTimer) { now in
            if let last = self.lastUpdate, Calendar.current.isDate(now, inSameDayAs: last) {
                return
            }

            let comps = Calendar.current.dateComponents([.hour, .minute], from: now)

            // every 5am
            if comps.hour == 5 && comps.minute == 1 {
                self.createScheduled()
                self.lastUpdate = now
            }
        }
    }

    func fetchTrains() {
        if self.scheduled == nil {
            createScheduled()
        } else {
            self.trains = self.scheduled!.fetchScheduled()
            self.fetchLive()
        }
    }

    func createScheduled() {
        let url = URL(string: "https://www.caltrain.com")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let scheduled = Scheduled(html: String(data: data, encoding: .utf8)!)

                self.trains = scheduled.fetchScheduled()
                self.fetchLive()
            }
        }.resume()
    }

    func fetchLive() {
        let url = URL(string: "https://tracks-api.octalwise.com/trains")!

        var request = URLRequest(url: url)
        request.setValue("AUTH", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let data = try decoder.decode([Train].self, from: data)
                    let trainIDs = data.map { $0.id }

                    self.trains = self.trains!.filter { train in
                        trainIDs.first { train.id == $0 } == nil
                    } + data
                } catch {}
            }

            self.fetchStations()
        }.resume()
    }

    func fetchStations() {
        if let url = Bundle.main.url(forResource: "stations", withExtension: "json") {
            do {
                let json = try Data(contentsOf: url)
                let decoder = JSONDecoder()

                let data = try decoder.decode([StationInfo].self, from: json)
                let stations = Stations(stations: data)

                self.stations = stations.loadStations(trains: self.trains!)
            } catch {}
        }
    }

    func fetchAlerts() {
        let url = URL(string: "https://tracks-api.octalwise.com/alerts")!

        var request = URLRequest(url: url)
        request.setValue("AUTH", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let data = try decoder.decode([Alert].self, from: data)
                    self.alerts = data
                } catch {}
            }
        }.resume()
    }
}
