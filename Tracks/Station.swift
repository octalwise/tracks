// stations fetcher
struct Stations {
    let stations: [StationInfo]

    // load json info
    func loadStations(trains: [Train]) -> [BothStations] {
        self.stations.map { station in
            BothStations(
                name: station.name,

                north: Station(
                    id:    station.north,
                    name:  "\(station.name) Northbound",
                    train: trains.first { $0.location == station.north }?.id
                ),

                south: Station(
                    id:    station.south,
                    name:  "\(station.name) Southbound",
                    train: trains.first { $0.location == station.south }?.id
                )
            )
        }
    }
}

// json info
struct StationInfo: Decodable {
    // name
    let name: String

    // northbound id
    let north: Int

    // southbound id
    let south: Int
}

// northbound and southbound
struct BothStations: Codable, Hashable {
    // name
    let name: String

    // northbound
    let north: Station

    // southbound
    let south: Station
}

// single side
struct Station: Codable, Hashable {
    // station id
    let id: Int

    // name
    let name:  String

    // current train
    let train: Int?
}
