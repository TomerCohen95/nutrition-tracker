import Foundation

struct PersonalFood: Codable, Identifiable {
    static let storageKey = "personalFoodCatalog"

    var id = UUID()
    var name: String
    var calories: Int
    var protein: Int? = nil
    var defaultGrams: Int? = nil

    // A default weight indicates that nutrition is stored per 100 g.
    static func read(_ data: Data) -> [Self] {
        if !data.isEmpty {
            return (try? JSONDecoder().decode([Self].self, from: data)) ?? []
        }
        return defaults
    }

    private static let defaults: [Self] = {
        guard let encoded = Bundle.main.object(forInfoDictionaryKey: "MarkEatPersonalFoodSeed") as? String,
              let data = Data(base64Encoded: encoded) else { return [] }
        return (try? JSONDecoder().decode([Self].self, from: data)) ?? []
    }()
}
