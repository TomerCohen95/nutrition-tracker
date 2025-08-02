//
//  AppIntent.swift
//  NutritionWidget
//
//  Interactive widget intents for marking foods as eaten
//

import Foundation
import WidgetKit
import AppIntents
import SwiftData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your nutrition widget." }
}

struct ToggleFoodStatusIntent: AppIntent {
    static var title: LocalizedStringResource { "Toggle Food Status" }
    static var description: IntentDescription { "Mark a food item as eaten or planned." }
    
    @Parameter(title: "Food Item ID")
    var foodItemId: String
    
    init() {}
    
    init(foodItemId: String) {
        self.foodItemId = foodItemId
    }
    
    func perform() async throws -> some IntentResult {
        // Create model container with App Group support
        let schema = Schema([FoodItem.self])
        let modelConfiguration = ModelConfiguration(
            "NutritionTracker",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.tomercode.nutritiontracker")
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            
            // Find the food item by ID
            guard let uuid = UUID(uuidString: foodItemId) else {
                throw IntentError.foodItemNotFound
            }
            
            let descriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate<FoodItem> { item in
                    item.id == uuid
                }
            )
            
            let items = try context.fetch(descriptor)
            
            if let foodItem = items.first {
                // Toggle the status
                foodItem.toggleStatus()
                
                try context.save()
                
                // Request widget timeline reload
                WidgetCenter.shared.reloadTimelines(ofKind: "NutritionWidget")
                
                return .result()
            } else {
                throw IntentError.foodItemNotFound
            }
            
        } catch {
            print("Error toggling food status: \(error)")
            throw IntentError.databaseError
        }
    }
}

enum IntentError: Error, LocalizedError {
    case foodItemNotFound
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .foodItemNotFound:
            return "Food item not found"
        case .databaseError:
            return "Database error occurred"
        }
    }
}
