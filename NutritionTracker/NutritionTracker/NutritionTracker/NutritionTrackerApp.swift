//
//  NutritionTrackerApp.swift
//  NutritionTracker
//
//  Main app entry point with SwiftData configuration
//

import SwiftUI
import SwiftData

@main
struct NutritionTrackerApp: App {
    // App Group identifier for sharing data with widget
    static let appGroupID = "group.com.yourname.nutritiontracker"
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodItem.self,
            FoodHistory.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}