import Foundation
import Combine



/// Employee representation returned by `/web/all-user-current-location`
struct Worker: Codable, Identifiable {
    let userID: Int
    let userName: String
    var locationName: String?

    var id: Int { userID }

    enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case userName = "name"
        case currentLocation
    }

    enum LocationKeys: String, CodingKey {
        case locationId
        case locationName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(Int.self, forKey: .userID)
        userName = try container.decode(String.self, forKey: .userName)

        if let locContainer = try? container.nestedContainer(keyedBy: LocationKeys.self,
                                                             forKey: .currentLocation) {
            locationName = try locContainer.decode(String.self, forKey: .locationName)
        } else {
            locationName = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(userName, forKey: .userName)
        if let name = locationName {
            var loc = container.nestedContainer(keyedBy: LocationKeys.self,
                                               forKey: .currentLocation)
            try loc.encode(name, forKey: .locationName)
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name     = "Name"
    case location = "Standort"
    var id: Self { self }
}

// Backend host helper for simulator/real device
private var backendHost: String {
#if targetEnvironment(simulator)
    return "localhost"
#else
    return "172.16.42.23"
#endif
}



final class WorkersListViewModel: ObservableObject {

    @Published var sortOption: SortOption = .name
    @Published var searchText: String = ""
    
    @Published private(set) var allWorkers: [Worker] = []
    @Published var errorMessage: String?
    
    // sfilter plius sortier funktion
    var filteredWorkers: [Worker] {
        let filtered = allWorkers.filter {
            searchText.isEmpty
            || $0.userName.localizedCaseInsensitiveContains(searchText)
        }
        switch sortOption {
        case .name:
            return filtered.sorted { $0.userName < $1.userName }
        case .location:
            return filtered.sorted {
                switch ($0.locationName, $1.locationName) {
                case let (a?, b?):    return a < b
                case (_?, nil):       return true
                case (nil, _?):       return false
                case (nil, nil):      return $0.userName < $1.userName
                }
            }
        }
    }
    
    init() {
        loadWorkers()
    }

    /// Loads workers with their current location from the backend.
    func loadWorkers() {
        errorMessage = nil
        allWorkers = []

        guard let url = URL(string: "http://\(backendHost):3000/web/all-user-current-location") else {
            errorMessage = "Ungültige URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "Keine Daten erhalten"
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([Worker].self, from: data)
                    self.allWorkers = decoded
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }.resume()
    }
}
