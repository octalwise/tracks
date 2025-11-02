import Foundation
import SwiftUI

struct ContentView: View {
    @State var trains: [Train]? = nil
    @State var alerts: [Alert]? = nil
    @State var stations: [BothStations]? = nil

    @State var lastUpdate: Date? = nil

    @State var scheduled: Scheduled? = nil
    @State var holidays: Holidays? = nil

    // every 90 seconds
    let fetchTimer =
        Timer.publish(every: 90, on: .main, in: .common).autoconnect()

    // every 5am
    let scheduledTimer =
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            // all stations view
            NavigationStack {
                ScrollView {
                    if self.stations != nil {
                        StationsView(trains: self.trains ?? [], stations: self.stations!)
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
            self.fetchStations()
            self.fetch()
        }
        .refreshable {
            self.fetch()
        }
        .onReceive(self.fetchTimer) { _ in
            // every 90 seconds
            self.fetch()
        }
        .onReceive(self.scheduledTimer) { now in
            if let last = self.lastUpdate, Calendar.current.isDate(now, inSameDayAs: last) {
                return
            }

            let comps = Calendar.current.dateComponents([.hour, .minute], from: now)

            // every 5am
            if comps.hour! > 5 || (comps.hour! == 5 && comps.minute! >= 0) {
                self.fetch(scheduled: true)
                self.lastUpdate = now
            }
        }
    }

    func fetch(scheduled fetchScheduled: Bool = false) {
        var urls = [
            "live": (url: "https://tracks-api.octalwise.com/trains", auth: true),
            "alerts": (url: "https://tracks-api.octalwise.com/alerts", auth: true)
        ]

        if self.holidays == nil {
            urls["holidays"] = (url: "https://www.caltrain.com/schedules/holiday-service-schedules", auth: false)
        }
        if self.scheduled == nil || fetchScheduled {
            urls["scheduled"] = (url: "https://www.caltrain.com", auth: false)
        }

        let group = DispatchGroup()
        var res: [String: Data] = [:]

        for (label, req) in urls {
            group.enter()

            let url = URL(string: req.url)!
            var request = URLRequest(url: url)

            if req.auth {
                request.setValue("AUTH", forHTTPHeaderField: "Authorization")
            }

            URLSession.shared.dataTask(with: request) { data, _, _ in
                if let data = data {
                    res[label] = data
                }

                group.leave()
            }.resume()
        }

        group.notify(queue: .main) {
            if self.holidays == nil {
                let html = String(data: res["holidays"]!, encoding: .utf8)!
                self.holidays = Holidays(html: html)
            }
            if self.scheduled == nil || fetchScheduled {
                let html = String(data: res["scheduled"]!, encoding: .utf8)!
                self.scheduled = Scheduled(html: html, holidays: self.holidays!)
            }

            self.trains = self.scheduled!.fetch()

            if let live = res["live"] {
                loadLive(data: live)
            }
            fetchStations()

            if let alerts = res["alerts"] {
                loadAlerts(data: alerts)
            }
        }
    }

    func loadLive(data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        do {
            let data = try decoder.decode([Train].self, from: data)
            let trainIDs = data.map { $0.id }

            self.trains = self.trains!.filter { train in
                trainIDs.first { train.id == $0 } == nil
            } + data
        } catch {}
    }

    func fetchStations() {
        if let url = Bundle.main.url(forResource: "stations", withExtension: "json") {
            do {
                let json = try Data(contentsOf: url)
                let decoder = JSONDecoder()

                let data = try decoder.decode([StationInfo].self, from: json)
                let stations = Stations(stations: data)

                self.stations = stations.loadStations(trains: self.trains ?? [])
            } catch {}
        }
    }

    func loadAlerts(data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        do {
            let data = try decoder.decode([Alert].self, from: data)
            self.alerts = data
        } catch {}
    }
}
