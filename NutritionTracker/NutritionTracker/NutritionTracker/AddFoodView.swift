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
    
    @Query(sort: \FoodHistory.lastUsed, order: .reverse) private var foodHistory: [FoodHistory]
    
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
            Form {
                // Recent Foods Section (Quick-Pick)
                if !foodHistory.isEmpty {
                    Section(header: Text("Recent Foods")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(foodHistory.prefix(10)), id: \.name) { historyItem in
                                    Button(action: {
                                        selectFromHistory(historyItem)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(historyItem.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)
                                            
                                            Text("\(historyItem.calories) kcal")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .frame(width: 100)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                Section(header: Text("Food Details")) {
                    TextField("Food name", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section {
                    Button("Add Food Item") {
                        addFoodItem()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(foodName.isEmpty || calories.isEmpty)
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
        } catch {
            print("Error saving to history: \(error)")
        }
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: [FoodItem.self, FoodHistory.self], inMemory: true)
}