struct Stations {
    let stations: [StationInfo]

    func loadStations(trains: [Train]) -> [BothStations] {
        self.stations.map { station in
            BothStations(
                name: station.name,

                north: Station(
                    id: station.north,
                    train: trains.first { $0.location == station.north }?.id
                ),

                south: Station(
                    id: station.south,
                    train: trains.first { $0.location == station.south }?.id
                )
            )
        }
    }
}

struct StationInfo: Decodable {
    let name: String
    let north: Int
    let south: Int
}

struct BothStations: Codable, Hashable {
    let name: String
    let north: Station
    let south: Station

    func contains(id: Int) -> Bool {
        id == self.north.id || id == self.south.id
    }
}

struct Station: Codable, Hashable {
    let id: Int
    let train: Int?
}
