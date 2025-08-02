//
//  FoodHistory.swift
//  NutritionTracker
//
//  Food History model for Quick-Pick functionality (Deliverable 4)
//

import SwiftData
import Foundation

@Model
final class FoodHistory {
    var name: String
    var calories: Int
    var lastUsed: Date
    var usageCount: Int
    
    init(name: String, calories: Int) {
        self.name = name
        self.calories = calories
        self.lastUsed = Date()
        self.usageCount = 1
    }
    
    // Update when food is used again
    func markAsUsed() {
        self.lastUsed = Date()
        self.usageCount += 1
    }
    
    // Check if this matches another food (same name and calories)
    func matches(name: String, calories: Int) -> Bool {
        return self.name.lowercased() == name.lowercased() && self.calories == calories
    }
}

// Extension for easy display
extension FoodHistory {
    var displayText: String {
        return "\(name) - \(calories) kcal"
    }
}