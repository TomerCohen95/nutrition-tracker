//
//  DayView.swift
//  NutritionTracker
//
//  A reusable day view component that can display any date
//

import SwiftUI
import SwiftData
import WidgetKit
import UIKit

struct DayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var allFoodItems: [FoodItem]
    @Query(sort: \CalorieGoal.effectiveDate, order: .reverse) var calorieGoals: [CalorieGoal]
    
    let date: Date
    
    @State private var showingAddFood = false
    @State private var showingSettings = false
    @State private var showingCopyTodays = false
    @State private var selectedItemToCopy: FoodItem?
    @State private var showingEditFood = false
    @State private var selectedItemToEdit: FoodItem?
    @State private var isEditing = false
    @State private var editedCalories = ""
    
    // Dynamic daily calorie goal based on the provided date
    private var dailyGoal: Int {
        CalorieGoal.currentGoal(for: date, from: calorieGoals)
    }
    
    // Filter items for the specific date
    private var dayItems: [FoodItem] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return allFoodItems.filter { item in
            item.date >= startOfDay && item.date < endOfDay
        }.sorted { $0.createdAt < $1.createdAt }
    }
    
    // Calculate calories eaten for this date
    private var caloriesEaten: Int {
        dayItems
            .filter { $0.status == .eaten }
            .reduce(0) { $0 + $1.calories }
    }
    
    // Calculate remaining calories for this date
    private var remainingCalories: Int {
        dailyGoal - caloriesEaten
    }
    
    // Check if this is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Format date for display
    private var dateString: String {
        if isToday {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.paddingM) {
                // Settings button in toolbar instead of header
                // (moved to SwipeableDaysView toolbar)
                
                // Calorie Summary Card
                VStack(spacing: AppTheme.paddingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                            Text("Progress")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            HStack(alignment: .bottom, spacing: AppTheme.paddingXS) {
                                Text("\(caloriesEaten)")
                                    .font(AppTheme.titleFont)
                                    .foregroundColor(AppTheme.primaryGreen)
                                
                                Text("/ \(dailyGoal) kcal")
                                    .font(AppTheme.bodyFont)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .offset(y: -2)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: AppTheme.paddingXS) {
                            if remainingCalories >= 0 {
                                Text("Remaining")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("\(remainingCalories) kcal")
                                    .font(AppTheme.headlineFont)
                                    .foregroundColor(AppTheme.primaryGreen)
                            } else {
                                Text("Over by")
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("\(abs(remainingCalories)) kcal")
                                    .font(AppTheme.headlineFont)
                                    .foregroundColor(AppTheme.accentOrange)
                            }
                        }
                    }
                    
                    // Progress Bar
                    ProgressView(value: min(Double(caloriesEaten), Double(dailyGoal)), total: Double(dailyGoal))
                        .tint(remainingCalories >= 0 ? AppTheme.primaryGreen : AppTheme.accentOrange)
                        .scaleEffect(y: 2)
                }
                .padding(AppTheme.paddingL)
                .cardStyle(backgroundColor: AppTheme.adaptiveLightGreen(colorScheme))
                
                // Food Items Section
                VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                    HStack {
                        Text("Meals")
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
                    
                    if dayItems.isEmpty {
                        // Empty State Card
                        VStack(spacing: AppTheme.paddingM) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.textTertiary)
                            
                            Text("No meals added")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text("Add meals to track nutrition for this day")
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
                            ForEach(dayItems, id: \.id) { item in
                                FoodItemCard(item: item, onToggle: {
                                    toggleItemStatus(item)
                                }, onUpdate: {
                                    // Trigger UI refresh after calorie edit
                                    WidgetCenter.shared.reloadAllTimelines()
                                }, onEdit: {
                                    selectedItemToEdit = item
                                    showingEditFood = true
                                }, onCopy: {
                                    showCopyToDaysSheet(for: item)
                                }, onDuplicate: {
                                    duplicateItem(item)
                                }, onDelete: {
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
        .scrollContentBackground(.hidden)
        .background(AppTheme.secondaryBackground)
        .safeAreaInset(edge: .bottom) {
            // Add bottom padding to ensure content doesn't overlap tab bar
            Color.clear.frame(height: 20)
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView(targetDate: date)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingCopyTodays, onDismiss: {
            selectedItemToCopy = nil
        }) {
            if let item = selectedItemToCopy {
                CopyToDaysView(foodItem: item)
            } else {
                Text("Error loading food item")
                    .onAppear {
                        showingCopyTodays = false
                    }
            }
        }
        .sheet(isPresented: $showingEditFood, onDismiss: {
            selectedItemToEdit = nil
        }) {
            if let item = selectedItemToEdit {
                EditFoodView(foodItem: item)
            } else {
                Text("Error loading food item")
                    .onAppear {
                        showingEditFood = false
                    }
            }
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
    
    private func duplicateItem(_ item: FoodItem) {
        let duplicatedItem = FoodItem(name: item.name, calories: item.calories, date: date)
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

#Preview {
    DayView(date: Date())
        .modelContainer(for: FoodItem.self, inMemory: true)
}