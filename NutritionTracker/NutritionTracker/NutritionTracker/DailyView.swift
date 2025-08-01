//
//  DailyView.swift
//  NutritionTracker
//
//  Daily view showing food items and calorie tracking (Deliverable 2)
//

import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFoodItems: [FoodItem]
    
    // Daily calorie goal (can be made configurable later)
    private let dailyGoal = 2000
    
    // Filter today's items
    private var todaysItems: [FoodItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return allFoodItems.filter { item in
            item.date >= today && item.date < tomorrow
        }.sorted { $0.createdAt < $1.createdAt }
    }
    
    // Calculate calories eaten
    private var caloriesEaten: Int {
        todaysItems
            .filter { $0.status == .eaten }
            .reduce(0) { $0 + $1.calories }
    }
    
    // Calculate remaining calories
    private var remainingCalories: Int {
        dailyGoal - caloriesEaten
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Calorie Summary Header
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Today's Progress")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("\(caloriesEaten)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("/ \(dailyGoal) kcal")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if remainingCalories >= 0 {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(remainingCalories) kcal")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("Over by")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(abs(remainingCalories)) kcal")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Progress Bar
                ProgressView(value: min(Double(caloriesEaten), Double(dailyGoal)), total: Double(dailyGoal))
                    .tint(remainingCalories >= 0 ? .green : .red)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Food Items List
            if todaysItems.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No food items today")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Tap the + button to add your first meal")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(todaysItems, id: \.id) { item in
                        FoodItemRow(item: item) {
                            toggleItemStatus(item)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func toggleItemStatus(_ item: FoodItem) {
        item.toggleStatus()
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating item status: \(error)")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todaysItems[index])
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting items: \(error)")
        }
    }
}

struct FoodItemRow: View {
    let item: FoodItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.status.systemImage)
                    .font(.title2)
                    .foregroundColor(item.status == .eaten ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(item.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(item.calories) kcal")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        DailyView()
            .navigationTitle("Nutrition Tracker")
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}