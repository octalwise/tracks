import Foundation
import SwiftUI

// main view
struct ContentView: View {
    @State var trains:   [Train]? = nil
    @State var alerts:   [Alert]? = nil
    @State var stations: [BothStations]? = nil

    // scheduled trains fetcher
    let scheduled: Scheduled? = nil

    // every 90 seconds
    let trainsTimer =
        Timer.publish(every: 90, on: .main, in: .common).autoconnect()

    // every 180 seconds
    let alertsTimer =
        Timer.publish(every: 180, on: .main, in: .common).autoconnect()

    // every 24 hours
    let scheduledTimer =
        Timer.publish(every: 86_400, on: .main, in: .common).autoconnect()

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
                        }
                    }
                }.navigationTitle("Stations")
            }
            .tabItem {
                Label("Stations", systemImage: "house.fill")
            }
            .padding()

            // trips view
            NavigationStack {
                ScrollView {
                    if self.stations != nil && self.trains != nil {
                        TripsView(
                            stations: self.stations!,
                            trains:   self.trains!,

                            from: self.stations!.first {
                                $0.name == "Menlo Park"
                            }!,
                            to: self.stations!.first {
                                $0.name == "Hillsdale"
                            }!
                        )
                    } else {
                        ProgressView() {
                            Text("Loading Trains")
                        }
                    }
                }.navigationTitle("Trips")
            }
            .tabItem {
                Label("Trips", systemImage: "map.fill")
            }
            .padding()

            // alerts view
            NavigationStack {
                ScrollView {
                    if self.alerts != nil {
                        AlertsView(alerts: self.alerts!)
                    } else {
                        ProgressView() {
                            Text("Loading Alerts")
                        }
                    }
                }.navigationTitle("Alerts")
            }
            .tabItem {
                Label("Alerts", systemImage: "exclamationmark.triangle.fill")
            }
            .padding()
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
        .onReceive(self.scheduledTimer) { _ in
            // every 24 hours
            self.createScheduled()
        }
    }

    // fetch trains
    func fetchTrains() {
        if self.scheduled == nil {
            createScheduled()
        } else {
            self.trains = self.scheduled!.fetchScheduled()
            self.fetchRealtime()
        }
    }

    // create scheduled
    func createScheduled() {
        let url = URL(string: "https://www.caltrain.com/?active_tab=route_explorer_tab")!

        // fetch caltrain site
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let scheduled = Scheduled(html: String(data: data, encoding: .utf8)!)

                self.trains = scheduled.fetchScheduled()
                self.fetchRealtime()
            }
        }.resume()
    }

    // fetch realtime trains
    func fetchRealtime() {
        let url = URL(string: "https://tracks-api.octalwise.com/trains")!

        // add auth header
        var request = URLRequest(url: url)
        request.setValue("AUTH", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        // fetch data from server
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

    // fetch stations
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

    // fetch alerts
    func fetchAlerts() {
        let url = URL(string: "https://tracks-api.octalwise.com/alerts")!

        // add auth header
        var request = URLRequest(url: url)
        request.setValue("AUTH", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        // fetch data from server
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
