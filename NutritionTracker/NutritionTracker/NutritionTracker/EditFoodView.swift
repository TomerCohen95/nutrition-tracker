//
//  EditFoodView.swift
//  NutritionTracker
//
//  Created by User on 2025-08-02.
//

import SwiftUI
import SwiftData
import WidgetKit

struct EditFoodSheetSelection: Identifiable {
    let id: UUID
    let item: FoodItem

    init(item: FoodItem) {
        self.id = item.id
        self.item = item
    }
}

struct EditFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    let foodItem: FoodItem
    
    @State private var name: String
    @State private var calories: String
    @State private var proteinGrams: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(foodItem: FoodItem) {
        self.foodItem = foodItem
        self._name = State(initialValue: foodItem.name)
        self._calories = State(initialValue: String(foodItem.calories))
        self._proteinGrams = State(initialValue: String(foodItem.proteinGrams))
        print(
            "✏️ EditFoodView init for \(foodItem.name) [id=\(foodItem.id.uuidString)] kcal=\(foodItem.calories) protein=\(foodItem.proteinGrams)"
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Edit Food")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    saveChanges()
                }
                .fontWeight(.semibold)
                .disabled(name.isEmpty || calories.isEmpty || proteinGrams.isEmpty)
            }
            .padding()
            
            // Form Content
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter food name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter calories", text: $calories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Protein")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField("Enter protein in grams", text: $proteinGrams)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Current values display
                VStack(spacing: 8) {
                    Text("Current: \(foodItem.name) - \(foodItem.calories) kcal - \(foodItem.proteinGrams)g protein")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            print(
                "✏️ EditFoodView appeared for \(foodItem.name) [id=\(foodItem.id.uuidString)]"
            )
        }
        .onDisappear {
            print(
                "✏️ EditFoodView disappeared for \(foodItem.name) [id=\(foodItem.id.uuidString)]"
            )
        }
    }
    
    private func saveChanges() {
        print(
            "✏️ Save requested for \(foodItem.name) [id=\(foodItem.id.uuidString)] newName=\(name) newCalories=\(calories) newProtein=\(proteinGrams)"
        )

        // Validate input
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a food name"
            showAlert = true
            print("❌ EditFoodView validation failed: empty name")
            return
        }
        
        guard let calorieValue = Int(calories), calorieValue > 0 else {
            alertMessage = "Please enter a valid number of calories"
            showAlert = true
            print("❌ EditFoodView validation failed: invalid calories=\(calories)")
            return
        }

        guard let proteinValue = Int(proteinGrams), proteinValue >= 0 else {
            alertMessage = "Please enter a valid number of protein grams"
            showAlert = true
            print("❌ EditFoodView validation failed: invalid protein=\(proteinGrams)")
            return
        }
        
        // Update the food item
        foodItem.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        foodItem.calories = calorieValue
        foodItem.proteinGrams = proteinValue
        
        do {
            try modelContext.save()
            print(
                "✅ EditFoodView saved \(foodItem.name) [id=\(foodItem.id.uuidString)] kcal=\(foodItem.calories) protein=\(foodItem.proteinGrams)"
            )
            
            // Refresh widget
            WidgetCenter.shared.reloadAllTimelines()
            
            dismiss()
        } catch {
            print("❌ EditFoodView save failed: \(error)")
            alertMessage = "Failed to save changes: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    @Previewable @State var sampleItem: FoodItem = {
        let item = FoodItem(name: "Apple", calories: 95, proteinGrams: 0, date: Date())
        item.status = .planned
        return item
    }()
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, configurations: config)
    
    EditFoodView(foodItem: sampleItem)
        .modelContainer(container)
}
