//
//  FoodHistoryManager.swift
//  NutritionTracker
//
//  Singleton manager for food history using UserDefaults with App Group
//  This provides 100% reliable persistence for the quick-pick feature
//

import Foundation
import Combine

/// Manages food history persistence using UserDefaults with App Group
/// This is a singleton that can be accessed from both the main app and widget
final class FoodHistoryManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = FoodHistoryManager()
    
    // MARK: - Constants
    
    private let appGroupID = "group.com.OneFifty.Aoo"
    private let historyKey = "foodHistoryItems"
    private let maxHistoryItems = 50
    
    // MARK: - Published Properties
    
    /// The current food history, sorted by most recently used
    @Published private(set) var history: [FoodHistoryItem] = []
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    private init() {
        // Use App Group UserDefaults for sharing between app and widget
        if let groupDefaults = UserDefaults(suiteName: appGroupID) {
            self.userDefaults = groupDefaults
            print("✅ FoodHistoryManager: Using App Group UserDefaults")
        } else {
            // Fallback to standard UserDefaults (should not happen in production)
            self.userDefaults = .standard
            print("⚠️ FoodHistoryManager: App Group not available, using standard UserDefaults")
        }
        
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// Load history from UserDefaults
    func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else {
            print("📦 FoodHistoryManager: No existing history found")
            history = []
            return
        }
        
        do {
            let items = try decoder.decode([FoodHistoryItem].self, from: data)
            // Sort by most recently used
            history = items.sorted { $0.lastUsed > $1.lastUsed }
            print("📦 FoodHistoryManager: Loaded \(history.count) items from storage")
        } catch {
            print("❌ FoodHistoryManager: Failed to decode history: \(error)")
            history = []
        }
    }
    
    /// Add a new food item or update existing one
    /// - Parameters:
    ///   - name: The food name
    ///   - calories: The calorie count
    ///   - proteinGrams: The protein count in grams
    func addOrUpdate(name: String, calories: Int, proteinGrams: Int) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, calories > 0, proteinGrams >= 0 else {
            print(
                "⚠️ FoodHistoryManager: Invalid input - name: '\(name)', calories: \(calories), protein: \(proteinGrams)"
            )
            return
        }
        
        // Check if item already exists
        if let existingIndex = history.firstIndex(where: {
            $0.matches(name: trimmedName, calories: calories, proteinGrams: proteinGrams)
        }) {
            // Update existing item
            let existingItem = history[existingIndex]
            let updatedItem = existingItem.withUpdatedUsage()
            history.remove(at: existingIndex)
            history.insert(updatedItem, at: 0) // Move to front (most recent)
            print("🔄 FoodHistoryManager: Updated existing item '\(trimmedName)' (usage count: \(updatedItem.usageCount))")
        } else {
            // Add new item
            let newItem = FoodHistoryItem(
                name: trimmedName,
                calories: calories,
                proteinGrams: proteinGrams
            )
            history.insert(newItem, at: 0) // Add to front
            print("➕ FoodHistoryManager: Added new item '\(trimmedName)'")
            
            // Trim old items if needed
            trimHistoryIfNeeded()
        }
        
        saveHistory()
    }
    
    /// Mark an item as used (updates lastUsed and usageCount)
    /// - Parameter item: The history item that was selected
    func markAsUsed(_ item: FoodHistoryItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else {
            print("⚠️ FoodHistoryManager: Item not found for marking as used")
            return
        }
        
        let updatedItem = history[index].withUpdatedUsage()
        history.remove(at: index)
        history.insert(updatedItem, at: 0) // Move to front
        
        saveHistory()
        print("✅ FoodHistoryManager: Marked '\(item.name)' as used")
    }
    
    /// Remove a specific item from history
    /// - Parameter item: The item to remove
    func remove(_ item: FoodHistoryItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
        print("🗑️ FoodHistoryManager: Removed '\(item.name)' from history")
    }
    
    /// Clear all history
    func clearAll() {
        history = []
        saveHistory()
        print("🧹 FoodHistoryManager: Cleared all history")
    }
    
    /// Get the most frequently used items
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of most frequently used items
    func getMostFrequent(limit: Int = 10) -> [FoodHistoryItem] {
        return Array(history.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
    }
    
    /// Get the most recently used items
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Array of most recently used items
    func getMostRecent(limit: Int = 10) -> [FoodHistoryItem] {
        return Array(history.prefix(limit))
    }
    
    /// Search history for items matching the query (case-insensitive contains match)
    /// - Parameters:
    ///   - query: The search string to match against food names
    ///   - limit: Maximum number of results to return (default 10)
    /// - Returns: Array of matching items sorted by usage frequency
    func search(query: String, limit: Int = 10) -> [FoodHistoryItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        
        return history
            .filter { $0.name.lowercased().contains(trimmed) }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Migration Support
    
    /// Import items from the old SwiftData FoodHistory model
    /// Call this once during migration
    /// - Parameter items: Array of tuples (name, calories, lastUsed, usageCount)
    func importFromLegacy(items: [(name: String, calories: Int, lastUsed: Date, usageCount: Int)]) {
        for item in items {
            let historyItem = FoodHistoryItem(
                name: item.name,
                calories: item.calories,
                proteinGrams: 0,
                lastUsed: item.lastUsed,
                usageCount: item.usageCount
            )
            
            // Only add if not already present
            if !history.contains(where: {
                $0.matches(name: item.name, calories: item.calories, proteinGrams: 0)
            }) {
                history.append(historyItem)
            }
        }
        
        // Sort and trim
        history.sort { $0.lastUsed > $1.lastUsed }
        trimHistoryIfNeeded()
        saveHistory()
        
        print("📥 FoodHistoryManager: Imported \(items.count) legacy items")
    }
    
    // MARK: - Private Methods
    
    private func saveHistory() {
        do {
            let data = try encoder.encode(history)
            userDefaults.set(data, forKey: historyKey)
            userDefaults.synchronize() // Force immediate save
            print("💾 FoodHistoryManager: Saved \(history.count) items to storage")
        } catch {
            print("❌ FoodHistoryManager: Failed to save history: \(error)")
        }
    }
    
    private func trimHistoryIfNeeded() {
        if history.count > maxHistoryItems {
            // Remove oldest items (they're at the end since we sort by lastUsed)
            let itemsToRemove = history.count - maxHistoryItems
            history.removeLast(itemsToRemove)
            print("✂️ FoodHistoryManager: Trimmed \(itemsToRemove) old items")
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension FoodHistoryManager {
    /// Print current state for debugging
    func debugPrint() {
        print("=== FoodHistoryManager Debug ===")
        print("Total items: \(history.count)")
        print("App Group ID: \(appGroupID)")
        print("UserDefaults suite: \(userDefaults.description)")
        for (index, item) in history.prefix(5).enumerated() {
            print(
                "  \(index + 1). \(item.name) - \(item.calories) kcal - \(item.proteinGrams)g protein (used \(item.usageCount)x)"
            )
        }
        if history.count > 5 {
            print("  ... and \(history.count - 5) more")
        }
        print("================================")
    }
    
    /// Add sample data for testing
    func addSampleData() {
        let samples = [
            ("Apple", 95, 0),
            ("Banana", 105, 1),
            ("Chicken Breast", 165, 31),
            ("Rice (1 cup)", 206, 4),
            ("Egg", 78, 6),
            ("Oatmeal", 150, 5),
            ("Greek Yogurt", 100, 17),
            ("Almonds (1 oz)", 164, 6)
        ]
        
        for (name, calories, proteinGrams) in samples {
            addOrUpdate(name: name, calories: calories, proteinGrams: proteinGrams)
        }
    }
}
#endif
