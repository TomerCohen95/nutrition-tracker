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
    var lastUsed: Date
    var usageCount: Int
    
    init(id: UUID = UUID(), name: String, calories: Int, lastUsed: Date = Date(), usageCount: Int = 1) {
        self.id = id
        self.name = name
        self.calories = calories
        self.lastUsed = lastUsed
        self.usageCount = usageCount
    }
    
    /// Check if this matches another food (same name, case-insensitive, and same calories)
    func matches(name: String, calories: Int) -> Bool {
        return self.name.lowercased() == name.lowercased() && self.calories == calories
    }
    
    /// Create a copy with updated usage stats
    func withUpdatedUsage() -> FoodHistoryItem {
        return FoodHistoryItem(
            id: self.id,
            name: self.name,
            calories: self.calories,
            lastUsed: Date(),
            usageCount: self.usageCount + 1
        )
    }
    
    /// Display text for UI
    var displayText: String {
        return "\(name) - \(calories) kcal"
    }
}