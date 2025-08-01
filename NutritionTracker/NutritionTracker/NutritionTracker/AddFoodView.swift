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
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
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
        
        // Create and save food item
        let foodItem = FoodItem(
            name: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
            calories: calorieValue
        )
        
        modelContext.insert(foodItem)
        
        do {
            try modelContext.save()
            
            // Force widget refresh immediately after saving
            WidgetCenter.shared.reloadAllTimelines()
            
            dismiss()
        } catch {
            alertMessage = "Failed to save food item: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: FoodItem.self, inMemory: true)
}