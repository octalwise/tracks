import Foundation
import SwiftUI

struct ContentView: View {
    @State var trains: [Train]? = nil
    @State var alerts: [Alert]? = nil
    @State var stations: [BothStations]? = nil

    @State var lastUpdate: Date? = nil

    @State var scheduled: Scheduled? = nil
    @State var holidays: Holidays? = nil

    @State var today: String?
    @State var service: String?

    // every 30 seconds
    let fetchTimer =
        Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    // every 3am
    let scheduledTimer =
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        let serviceTrains = serviceTrains()
        let altService = service != nil && service! != today!

        TabView {
            // all stations view
            NavigationSplitView {
                ScrollView {
                    if stations != nil {
                        StationsView(
                            trains: serviceTrains ?? [],
                            stations: stations!,
                            altService: altService
                        )
                        .toolbar {
                            if service != nil {
                                serviceButton()
                            }
                        }
                    }
                }
                .navigationTitle("Stations")
                .navigationSplitViewColumnWidth(ideal: 400)
            } detail: {
                NavigationStack {
                    ContentUnavailableView("Select a station or train", systemImage: "tram")
                }
            }
            .tabItem {
                Label("Stations", systemImage: "house.fill")
            }

            // trips view
            NavigationSplitView {
                ScrollView {
                    if stations != nil && serviceTrains != nil {
                        TripsView(
                            stations: stations!,
                            trains: serviceTrains!,
                            altService: altService,

                            from: stations!.first { $0.name == "Palo Alto" }!,
                            to: stations!.first { $0.name == "San Mateo" }!
                        )
                        .toolbar {
                            if service != nil {
                                serviceButton()
                            }
                        }
                    } else {
                        ProgressView() {
                            Text("Loading Trains")
                        }.padding(15)
                    }
                }
                .navigationTitle("Trips")
                .navigationSplitViewColumnWidth(ideal: 400)
            } detail: {
                NavigationStack {
                    ContentUnavailableView("Select a train", systemImage: "tram")
                }
            }
            .tabItem {
                Label("Trips", systemImage: "map.fill")
            }

            // alerts view
            NavigationStack {
                ScrollView {
                    if alerts != nil {
                        AlertsView(alerts: alerts!)
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
            loadStations()
            fetch()
            if laCalendar.component(.hour, from: Date()) >= 3 {
                lastUpdate = Date()
            }
        }
        .refreshable {
            fetch()
        }
        .onChange(of: service) {
            loadStations()
        }
        .onReceive(fetchTimer) { _ in
            // every 30 seconds
            fetch()
        }
        .onReceive(scheduledTimer) { now in
            if let last = lastUpdate, laCalendar.isDate(now, inSameDayAs: last) {
                return
            }

            // every 3am
            if laCalendar.component(.hour, from: now) >= 3 {
                fetch(full: true)
                lastUpdate = now
            }
        }
    }

    func serviceTrains() -> [Train]? {
        return trains?.filter { train in
            guard let service = service, let today = today else {
                return false
            }

            return train.service == service || (train.service == "normal" && service == today)
        }
    }

    func serviceButton() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Service", selection: $service) {
                    Label("Weekday", systemImage: "calendar").tag("weekday")
                    Label("Weekend", systemImage: "clock").tag("weekend")
                }
            } label: {
                Image(systemName: service == "weekday" ? "calendar" : "clock")
            }
        }
    }

    func fetch(full fullFetch: Bool = false) {
        var urls = [
            "live": (url: "https://tracks-api.octalwise.com/trains", auth: true),
            "alerts": (url: "https://tracks-api.octalwise.com/alerts", auth: true)
        ]

        if holidays == nil {
            urls["holidays"] = (url: "https://www.caltrain.com/schedules/holiday-service-schedules", auth: false)
        }
        if scheduled == nil || fullFetch {
            urls["scheduled"] = (url: "https://www.caltrain.com", auth: false)
        }

        let group = DispatchGroup()
        var res: [String: Data] = [:]

        for (label, req) in urls {
            group.enter()

            let url = URL(string: req.url)!
            var request = URLRequest(url: url)

            if req.auth {
                request.setValue("6a4668bc-cfe0-4647-9a2f-56b5e5ae3cc6", forHTTPHeaderField: "Authorization")
            }

            URLSession.shared.dataTask(with: request) { data, _, _ in
                if let data = data {
                    res[label] = data
                }

                group.leave()
            }.resume()
        }

        group.notify(queue: .main) {
            if holidays == nil {
                if let data = res["holidays"] {
                    let html = String(decoding: data, as: UTF8.self)
                    holidays = Holidays(html: html)
                } else {
                    return
                }
            }
            if scheduled == nil || fullFetch {
                if let data = res["scheduled"] {
                    let html = String(decoding: data, as: UTF8.self)
                    scheduled = Scheduled(html: html, holidays: holidays!)
                } else {
                    return
                }
            }

            let newToday = holidays!.service()
            if service == nil || fullFetch || newToday != today {
                service = newToday
            }
            today = newToday

            trains = scheduled!.fetch()

            if let live = res["live"] {
                loadLive(data: live)
            }
            loadStations()

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

            trains = data + trains!.filter { train in
                !trainIDs.contains(where: { train.id == $0 })
            }
        } catch {}
    }

    func loadStations() {
        stations = Stations(stations: STATIONS).loadStations(trains: serviceTrains() ?? [])
    }

    func loadAlerts(data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        do {
            let data = try decoder.decode([Alert].self, from: data)
            alerts = data
        } catch {}
    }
}
