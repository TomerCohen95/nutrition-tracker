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
    static let appGroupID = "group.com.OneFifty.Aoo"
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodItem.self,
            FoodHistory.self,
            CalorieGoal.self,
        ])
        
        // Get the shared container URL for app group
        guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Shared container could not be created.")
        }
        
        let modelConfiguration = ModelConfiguration(
            "NutritionTracker",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.OneFifty.Aoo")
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