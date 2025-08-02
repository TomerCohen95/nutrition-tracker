//
//  DailyView.swift
//  NutritionTracker
//
//  Daily view showing food items and calorie tracking (Deliverable 2)
//

import SwiftUI
import SwiftData
import WidgetKit

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Query private var allFoodItems: [FoodItem]
    @Query(sort: \CalorieGoal.effectiveDate, order: .reverse) var calorieGoals: [CalorieGoal]
    @State private var showingAddFood = false
    @State private var showingSettings = false
    
    // Dynamic daily calorie goal based on date
    private var dailyGoal: Int {
        CalorieGoal.currentGoal(for: Date(), from: calorieGoals)
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
    
    // Calculate remaining calories
    private var remainingCalories: Int {
        dailyGoal - caloriesEaten
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.paddingM) {
                // Calorie Summary Card
                VStack(spacing: AppTheme.paddingM) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                            Text("Today's Progress")
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
                        if todaysItems.isEmpty {
                            Text("No food items for today")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVStack(spacing: AppTheme.paddingS) {
                                ForEach(todaysItems, id: \.id) { item in
                                    FoodItemCard(item: item, onToggle: {
                                        toggleItemStatus(item)
                                    }, onDelete: {
                                        if let index = todaysItems.firstIndex(of: item) {
                                            deleteItems(offsets: IndexSet([index]))
                                        }
                                    })
                                }
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
}

struct FoodItemCard: View {
    @Environment(\.colorScheme) var colorScheme
    let item: FoodItem
    let onToggle: () -> Void
    let onDelete: (() -> Void)?
    
    init(item: FoodItem, onToggle: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.item = item
        self.onToggle = onToggle
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: AppTheme.paddingM) {
            // Status Toggle Button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(item.status == .eaten ? AppTheme.primaryGreen : AppTheme.cardBackground)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(item.status == .eaten ? AppTheme.primaryGreen : AppTheme.textTertiary, lineWidth: 2)
                        )
                    
                    if item.status == .eaten {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Food Info
            VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                Text(item.name)
                    .font(AppTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: AppTheme.paddingXS) {
                    Image(systemName: item.status == .eaten ? "checkmark.circle.fill" : "clock")
                        .font(.system(size: 12))
                        .foregroundColor(item.status == .eaten ? AppTheme.primaryGreen : AppTheme.textTertiary)
                    
                    Text(item.status.displayName)
                        .font(AppTheme.smallFont)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Calories Badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.calories)")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("kcal")
                    .font(AppTheme.smallFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.paddingS)
            .padding(.vertical, AppTheme.paddingXS)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusS)
                    .fill(item.status == .eaten ? AppTheme.adaptiveLightGreen(colorScheme) : AppTheme.adaptiveLightOrange(colorScheme))
            )
            
            // Delete Button
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppTheme.paddingM)
        .cardStyle()
    }
}

#Preview {
    NavigationView {
        DailyView()
            .navigationTitle("Nutrition Tracker")
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}