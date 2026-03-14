//
//  FoodItem.swift
//  NutritionTracker
//
//  SwiftData model for food items
//

import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var calories: Int
    var proteinGrams: Int = 0
    var date: Date
    var status: FoodStatus
    var createdAt: Date
    
    init(name: String, calories: Int, proteinGrams: Int = 0, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.date = date
        self.status = .planned
        self.createdAt = Date()
    }
    
    enum FoodStatus: String, CaseIterable, Codable {
        case planned = "planned"
        case eaten = "eaten"
        
        var displayName: String {
            switch self {
            case .planned:
                return "Planned"
            case .eaten:
                return "Eaten"
            }
        }
        
        var systemImage: String {
            switch self {
            case .planned:
                return "circle"
            case .eaten:
                return "checkmark.circle.fill"
            }
        }
    }
    
    // Helper to check if item is from today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Helper to toggle status
    func toggleStatus() {
        status = status == .planned ? .eaten : .planned
    }
}

// Extension for easier date handling
extension FoodItem {
    static func todaysItems(in context: ModelContext) -> [FoodItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { item in
                item.date >= today && item.date < tomorrow
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching today's items: \(error)")
            return []
        }
    }
}
