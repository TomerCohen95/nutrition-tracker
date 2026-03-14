//
//  FoodHistoryItem.swift
//  NutritionTracker
//
//  Simple Codable struct for food history - stored in UserDefaults
//  This replaces the SwiftData @Model which had reliability issues
//

import Foundation

/// Represents a food item in the user's history for quick-pick functionality
struct FoodHistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var calories: Int
    var proteinGrams: Int
    var lastUsed: Date
    var usageCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        proteinGrams: Int = 0,
        lastUsed: Date = Date(),
        usageCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.lastUsed = lastUsed
        self.usageCount = usageCount
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case calories
        case proteinGrams
        case lastUsed
        case usageCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        proteinGrams = try container.decodeIfPresent(Int.self, forKey: .proteinGrams) ?? 0
        lastUsed = try container.decode(Date.self, forKey: .lastUsed)
        usageCount = try container.decode(Int.self, forKey: .usageCount)
    }
    
    /// Check if this matches another food (same name, case-insensitive, and same calories)
    func matches(name: String, calories: Int, proteinGrams: Int) -> Bool {
        return self.name.lowercased() == name.lowercased()
            && self.calories == calories
            && self.proteinGrams == proteinGrams
    }
    
    /// Create a copy with updated usage stats
    func withUpdatedUsage() -> FoodHistoryItem {
        return FoodHistoryItem(
            id: self.id,
            name: self.name,
            calories: self.calories,
            proteinGrams: self.proteinGrams,
            lastUsed: Date(),
            usageCount: self.usageCount + 1
        )
    }
    
    /// Display text for UI
    var displayText: String {
        return "\(name) - \(calories) kcal - \(proteinGrams)g protein"
    }
}
