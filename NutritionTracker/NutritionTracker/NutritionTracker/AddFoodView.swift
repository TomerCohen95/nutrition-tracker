//
//  AddFoodView.swift
//  NutritionTracker
//
//  Screen for adding new food items (Deliverable 1)
//

import SwiftUI
import SwiftData
import WidgetKit
import Foundation

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Query(sort: \FoodHistory.lastUsed, order: .reverse) private var foodHistory: [FoodHistory]
    @State private var historyRefreshTrigger = false
    @State private var debugMessage = ""
    
    let targetDate: Date
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(targetDate: Date = Date()) {
        self.targetDate = targetDate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.paddingL) {
                    // Recent Foods Section (Quick-Pick)
                    VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                        HStack {
                            Text("Recent Foods")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Spacer()
                            
                            if !foodHistory.isEmpty {
                                Text("Tap to use")
                                    .font(AppTheme.smallFont)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        
                        if !foodHistory.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.paddingM) {
                                    ForEach(Array(foodHistory.prefix(10)), id: \.name) { historyItem in
                                        Button(action: {
                                            selectFromHistory(historyItem)
                                        }) {
                                            VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                                                Text(historyItem.name)
                                                    .font(AppTheme.captionFont)
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text("\(historyItem.calories) kcal")
                                                    .font(AppTheme.smallFont)
                                                    .foregroundColor(AppTheme.primaryGreen)
                                                    .fontWeight(.medium)
                                            }
                                            .frame(width: 90, alignment: .leading)
                                            .padding(AppTheme.paddingS)
                                            .background(AppTheme.adaptiveLightGreen(colorScheme))
                                            .cornerRadius(AppTheme.radiusS)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, AppTheme.paddingM)
                            }
                        } else {
                            // Empty state message
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(AppTheme.textSecondary)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No recent foods yet")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text("Add some foods below and they'll appear here for quick selection")
                                        .font(AppTheme.smallFont)
                                        .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(AppTheme.paddingM)
                            .background(AppTheme.secondaryBackground)
                            .cornerRadius(AppTheme.radiusS)
                        }
                        
                        // Debug section (can be removed in production)
                        if !debugMessage.isEmpty {
                            Text("Debug: \(debugMessage)")
                                .font(AppTheme.smallFont)
                                .foregroundColor(.orange)
                                .padding(.top, AppTheme.paddingXS)
                        }
                        
                        // History stats for debugging
                        Text("History count: \(foodHistory.count)")
                            .font(AppTheme.smallFont)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.top, AppTheme.paddingXS)
                    }
                    .padding(.horizontal, AppTheme.paddingM)
                    
                    
                    // Food Details Card
                    VStack(spacing: AppTheme.paddingL) {
                        VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                            Text("Food Details")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            VStack(spacing: AppTheme.paddingM) {
                                VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                                    Text("Food Name")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    TextField("Enter food name", text: $foodName)
                                        .font(AppTheme.bodyFont)
                                        .padding(AppTheme.paddingM)
                                        .background(AppTheme.secondaryBackground)
                                        .cornerRadius(AppTheme.radiusS)
                                }
                                
                                VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                                    Text("Calories")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    TextField("Enter calories", text: $calories)
                                        .font(AppTheme.bodyFont)
                                        .keyboardType(.numberPad)
                                        .padding(AppTheme.paddingM)
                                        .background(AppTheme.secondaryBackground)
                                        .cornerRadius(AppTheme.radiusS)
                                }
                            }
                        }
                        .padding(AppTheme.paddingL)
                        .cardStyle()
                        
                        // Add Button
                        Button("Add Food Item") {
                            addFoodItem()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(foodName.isEmpty || calories.isEmpty)
                        .opacity(foodName.isEmpty || calories.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, AppTheme.paddingM)
                }
                .padding(.vertical, AppTheme.paddingL)
            }
            .background(AppTheme.secondaryBackground)
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                print("📱 AddFoodView appeared - History count: \(foodHistory.count)")
                if foodHistory.count == 0 {
                    debugMessage = "No history found on view appear"
                }
            }
            .onChange(of: foodHistory.count) { oldCount, newCount in
                print("📊 History count changed: \(oldCount) → \(newCount)")
                if newCount == 0 && oldCount > 0 {
                    debugMessage = "History became empty! Was \(oldCount)"
                }
            }
        }
    }
    
    private func addFoodItem() {
        print("🍎 Adding food item: \(foodName) - \(calories) kcal")
        
        // Validate input
        guard !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a food name"
            showingAlert = true
            return
        }
        
        guard let calorieValue = Int(calories), calorieValue > 0 else {
            alertMessage = "Please enter a valid number of calories"
            showingAlert = true
            return
        }
        
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create and save food item with target date
        let foodItem = FoodItem(
            name: trimmedName,
            calories: calorieValue
        )
        
        // Set the date to the target date (for weekly planning)
        foodItem.date = Calendar.current.startOfDay(for: targetDate)
        
        modelContext.insert(foodItem)
        
        do {
            try modelContext.save()
            print("✅ Food item saved successfully")
            
            // Add to food history (prevent duplicates)
            saveToHistory(name: trimmedName, calories: calorieValue)
            
            // Force widget refresh immediately after saving
            WidgetCenter.shared.reloadAllTimelines()
            
            dismiss()
        } catch {
            print("❌ Failed to save food item: \(error)")
            alertMessage = "Failed to save food item: \(error.localizedDescription)"
            showingAlert = true
            debugMessage = "Save failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - History Functions
    
    private func selectFromHistory(_ historyItem: FoodHistory) {
        foodName = historyItem.name
        calories = String(historyItem.calories)
        
        // Update usage count and last used date
        historyItem.markAsUsed()
        
        do {
            try modelContext.save()
            print("✅ History usage updated for: \(historyItem.name)")
        } catch {
            print("❌ Error updating history usage: \(error)")
            debugMessage = "Failed to update usage stats"
        }
    }
    
    private func saveToHistory(name: String, calories: Int) {
        print("📝 Saving to history: \(name) - \(calories) kcal")
        
        // Check if already exists in history
        let existingItem = foodHistory.first { $0.matches(name: name, calories: calories) }
        
        if let existing = existingItem {
            // Update existing item
            print("🔄 Updating existing history item")
            existing.markAsUsed()
        } else {
            // Create new history item
            print("➕ Creating new history item")
            let newHistoryItem = FoodHistory(name: name, calories: calories)
            modelContext.insert(newHistoryItem)
            
            // Safer history cleanup - limit to 30 items with better bounds checking
            cleanupOldHistory()
        }
        
        do {
            try modelContext.save()
            print("✅ History saved successfully. Current count: \(foodHistory.count)")
            
            // Trigger view refresh
            historyRefreshTrigger.toggle()
            
            // Verify the save worked
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("🔍 Post-save verification: \(foodHistory.count) items in history")
            }
        } catch {
            print("❌ Error saving to history: \(error)")
            debugMessage = "Failed to save food to history"
        }
    }
    
    private func cleanupOldHistory() {
        let maxHistoryItems = 30
        
        // Only cleanup if we actually exceed the limit
        guard foodHistory.count >= maxHistoryItems else {
            print("📊 History count (\(foodHistory.count)) below limit, no cleanup needed")
            return
        }
        
        print("🧹 Cleaning up old history items. Current count: \(foodHistory.count)")
        
        // Sort by lastUsed date (oldest first)
        let sortedHistory = foodHistory.sorted { $0.lastUsed < $1.lastUsed }
        
        // Calculate how many items to remove
        let itemsToRemove = foodHistory.count - maxHistoryItems + 1 // +1 for the new item being added
        
        // Safety check - never remove more than half the items
        let safeRemovalCount = min(itemsToRemove, foodHistory.count / 2)
        
        guard safeRemovalCount > 0 else {
            print("⚠️ Safe removal count is 0, skipping cleanup")
            return
        }
        
        print("🗑️ Removing \(safeRemovalCount) oldest items")
        
        // Remove the oldest items
        for i in 0..<safeRemovalCount {
            if i < sortedHistory.count {
                let itemToDelete = sortedHistory[i]
                print("🗑️ Deleting: \(itemToDelete.name) (last used: \(itemToDelete.lastUsed))")
                modelContext.delete(itemToDelete)
            }
        }
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: [FoodItem.self, FoodHistory.self], inMemory: true)
}