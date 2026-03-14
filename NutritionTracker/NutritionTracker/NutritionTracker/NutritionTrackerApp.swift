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
    
    // Key for tracking if migration has been done
    private static let migrationKey = "foodHistoryMigrationCompleted"
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodItem.self,
            CalorieGoal.self,
            // Note: FoodHistory is now stored in UserDefaults via FoodHistoryManager
            // We keep it in schema temporarily for migration purposes only
            FoodHistory.self,
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
                .onAppear {
                    migrateOldFoodHistoryIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Migration
    
    /// Migrates old SwiftData FoodHistory items to the new UserDefaults-based system
    private func migrateOldFoodHistoryIfNeeded() {
        let userDefaults = UserDefaults.standard
        
        // Check if migration has already been completed
        guard !userDefaults.bool(forKey: Self.migrationKey) else {
            print("📦 Migration already completed, skipping")
            return
        }
        
        print("🔄 Starting FoodHistory migration from SwiftData to UserDefaults...")
        
        let context = sharedModelContainer.mainContext
        
        // Fetch all existing FoodHistory items
        let fetchDescriptor = FetchDescriptor<FoodHistory>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        
        do {
            let oldHistoryItems = try context.fetch(fetchDescriptor)
            
            if oldHistoryItems.isEmpty {
                print("📦 No old history items to migrate")
            } else {
                print("📦 Found \(oldHistoryItems.count) items to migrate")
                
                // Convert to tuples for the manager
                let legacyItems = oldHistoryItems.map { item in
                    (name: item.name, calories: item.calories, lastUsed: item.lastUsed, usageCount: item.usageCount)
                }
                
                // Import into new system
                FoodHistoryManager.shared.importFromLegacy(items: legacyItems)
                
                print("✅ Migration completed successfully")
                
                // Optional: Clean up old SwiftData items to save space
                // Uncomment if you want to remove old data after migration
                // for item in oldHistoryItems {
                //     context.delete(item)
                // }
                // try context.save()
            }
            
            // Mark migration as completed
            userDefaults.set(true, forKey: Self.migrationKey)
            userDefaults.synchronize()
            
        } catch {
            print("❌ Migration failed: \(error)")
            // Don't mark as completed so we can retry
        }
    }
}