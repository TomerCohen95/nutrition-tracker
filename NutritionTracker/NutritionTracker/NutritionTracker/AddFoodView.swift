//
//  AddFoodView.swift
//  NutritionTracker
//
//  Screen for adding new food items (Deliverable 1)
//

import SwiftUI
import SwiftData
import WidgetKit

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Query(sort: \FoodHistory.lastUsed, order: .reverse) private var foodHistory: [FoodHistory]
    @State private var historyRefreshTrigger = false
    
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
        }
    }
    
    private func addFoodItem() {
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
        
        // Create and save food item with target date
        let foodItem = FoodItem(
            name: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: calorieValue
        )
        
        // Set the date to the target date (for weekly planning)
        foodItem.date = Calendar.current.startOfDay(for: targetDate)
        
        modelContext.insert(foodItem)
        
        do {
            try modelContext.save()
            
            // Add to food history (prevent duplicates)
            saveToHistory(name: foodName.trimmingCharacters(in: .whitespacesAndNewlines), calories: calorieValue)
            
            // Force widget refresh immediately after saving
            WidgetCenter.shared.reloadAllTimelines()
            
            dismiss()
        } catch {
            alertMessage = "Failed to save food item: \(error.localizedDescription)"
            showingAlert = true
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
        } catch {
            print("Error updating history usage: \(error)")
        }
    }
    
    private func saveToHistory(name: String, calories: Int) {
        // Check if already exists in history
        let existingItem = foodHistory.first { $0.matches(name: name, calories: calories) }
        
        if let existing = existingItem {
            // Update existing item
            existing.markAsUsed()
        } else {
            // Create new history item
            let newHistoryItem = FoodHistory(name: name, calories: calories)
            modelContext.insert(newHistoryItem)
            
            // Limit history to 30 items
            if foodHistory.count >= 30 {
                let oldestItems = foodHistory.sorted { $0.lastUsed < $1.lastUsed }
                for i in 0..<(foodHistory.count - 29) {
                    modelContext.delete(oldestItems[i])
                }
            }
        }
        
        do {
            try modelContext.save()
            // Trigger view refresh
            historyRefreshTrigger.toggle()
        } catch {
            print("Error saving to history: \(error)")
        }
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: [FoodItem.self, FoodHistory.self], inMemory: true)
}