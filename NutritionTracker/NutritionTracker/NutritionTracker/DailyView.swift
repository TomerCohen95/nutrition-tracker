//
//  DailyView.swift
//  NutritionTracker
//
//  Daily view showing food items and calorie tracking (Deliverable 2)
//

import SwiftData
import SwiftUI
import UIKit
import WidgetKit

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var allFoodItems: [FoodItem]
    @Query(sort: \CalorieGoal.effectiveDate, order: .reverse) var calorieGoals: [CalorieGoal]
    @State private var showingAddFood = false
    @State private var showingSettings = false
    @State private var showingCopyTodays = false
    @State private var selectedItemToCopy: FoodItem?
    @State private var selectedItemToEdit: EditFoodSheetSelection?
    @State private var isEditing = false
    @State private var editedCalories = ""

    // Dynamic daily calorie goal based on date
    private var dailyGoal: Int {
        CalorieGoal.currentGoal(for: Date(), from: calorieGoals)
    }

    private var dailyProteinGoal: Int {
        CalorieGoal.currentProteinGoal(for: Date(), from: calorieGoals)
    }

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

    // Calculate planned calories (including both eaten and planned items)
    private var caloriesPlanned: Int {
        todaysItems
            .reduce(0) { $0 + $1.calories }
    }

    private var proteinEaten: Int {
        todaysItems
            .filter { $0.status == .eaten }
            .reduce(0) { $0 + $1.proteinGrams }
    }

    private var proteinPlanned: Int {
        todaysItems
            .reduce(0) { $0 + $1.proteinGrams }
    }

    // Calculate remaining calories
    private var remainingCalories: Int {
        dailyGoal - caloriesEaten
    }

    // Calculate remaining planned calories
    private var remainingPlannedCalories: Int {
        dailyGoal - caloriesPlanned
    }

    private var remainingProtein: Int {
        dailyProteinGoal - proteinEaten
    }

    private var remainingPlannedProtein: Int {
        dailyProteinGoal - proteinPlanned
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.paddingS) {
                NutritionProgressCard(
                    title: "Today's Progress",
                    dailyGoal: dailyGoal,
                    dailyProteinGoal: dailyProteinGoal,
                    caloriesEaten: caloriesEaten,
                    caloriesPlanned: caloriesPlanned,
                    proteinEaten: proteinEaten,
                    proteinPlanned: proteinPlanned,
                    remainingCalories: remainingCalories,
                    remainingPlannedCalories: remainingPlannedCalories,
                    remainingProtein: remainingProtein,
                    remainingPlannedProtein: remainingPlannedProtein
                )

                // Food Items Section
                VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                    HStack {
                        Text("Today's Meals")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        Button {
                            showingAddFood = true
                        } label: {
                            HStack(spacing: AppTheme.paddingXS) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Add Food")
                                    .font(AppTheme.captionFont)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    if todaysItems.isEmpty {
                        // Empty State Card
                        VStack(spacing: AppTheme.paddingM) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.textTertiary)

                            Text("No meals added yet")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.textSecondary)

                            Text("Start tracking your nutrition by adding your first meal")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.paddingXL)
                        .cardStyle()
                    } else {
                        // Food Items Cards
                        LazyVStack(spacing: AppTheme.paddingS) {
                            ForEach(todaysItems, id: \.id) { item in
                                FoodItemCard(
                                    item: item,
                                    onToggle: {
                                        toggleItemStatus(item)
                                    },
                                    onUpdate: {
                                        // Trigger UI refresh after calorie edit
                                        // The @Query will automatically update, but we can add additional logic here if needed
                                        WidgetCenter.shared.reloadAllTimelines()
                                    },
                                    onEdit: {
                                        presentEditSheet(for: item)
                                    },
                                    onCopy: {
                                        showCopyToDaysSheet(for: item)
                                    },
                                    onDuplicate: {
                                        duplicateItem(item)
                                    },
                                    onDelete: {
                                        deleteItem(item)
                                    })
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)
            }
            .padding(.vertical, AppTheme.paddingM)
        }
        .background(AppTheme.secondaryBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddFood = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(
            isPresented: $showingCopyTodays,
            onDismiss: {
                selectedItemToCopy = nil
            }
        ) {
            if let item = selectedItemToCopy {
                CopyToDaysView(foodItem: item)
            } else {
                Text("Error loading food item")
                    .onAppear {
                        showingCopyTodays = false
                    }
            }
        }
        .sheet(item: $selectedItemToEdit, onDismiss: {
            print("✏️ DailyView dismissed edit sheet")
        }) { selection in
            EditFoodView(foodItem: selection.item)
        }
    }

    private func toggleItemStatus(_ item: FoodItem) {
        item.toggleStatus()

        do {
            try modelContext.save()

            // Refresh widget when status changes
            WidgetCenter.shared.reloadAllTimelines()
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

            // Refresh widget when items are deleted
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error deleting items: \(error)")
        }
    }

    private func deleteItem(_ item: FoodItem) {
        modelContext.delete(item)

        do {
            try modelContext.save()

            // Refresh widget when item is deleted
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error deleting item: \(error)")
        }
    }

    private func showCopyToDaysSheet(for item: FoodItem) {
        selectedItemToCopy = item
        showingCopyTodays = true
    }

    private func presentEditSheet(for item: FoodItem) {
        print("✏️ DailyView presenting edit sheet for \(item.name) [id=\(item.id.uuidString)]")
        selectedItemToEdit = EditFoodSheetSelection(item: item)
    }

    private func duplicateItem(_ item: FoodItem) {
        let duplicatedItem = FoodItem(
            name: item.name,
            calories: item.calories,
            proteinGrams: item.proteinGrams,
            date: Date()
        )
        modelContext.insert(duplicatedItem)

        do {
            try modelContext.save()

            // Refresh widget when item is duplicated
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error duplicating item: \(error)")
        }
    }
}

// FoodItemCard moved to separate file: FoodItemCard.swift

#Preview {
    NavigationView {
        DailyView()
            .navigationTitle("Nutrition Tracker")
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}
