//
//  WeeklyPlannerView.swift
//  NutritionTracker
//
//  Weekly meal planning and day copying functionality (Deliverable 6)
//

import SwiftUI
import SwiftData
import WidgetKit

struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFoodItems: [FoodItem]
    @Query(sort: \CalorieGoal.effectiveDate, order: .reverse) var calorieGoals: [CalorieGoal]
    
    @State private var selectedDate = Date()
    @State private var showingAddFood = false
    @State private var showingCopyDayAlert = false
    @State private var copyDestinationDate = Date()
    @State private var showingCopyConfirmation = false
    
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var selectedDayItems: [FoodItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return allFoodItems.filter { item in
            item.date >= startOfDay && item.date < endOfDay
        }.sorted { $0.createdAt < $1.createdAt }
    }
    
    private var caloriesEaten: Int {
        selectedDayItems
            .filter { $0.status == .eaten }
            .reduce(0) { $0 + $1.calories }
    }
    
    private var dailyGoal: Int {
        CalorieGoal.currentGoal(for: selectedDate, from: calorieGoals)
    }
    
    private var remainingCalories: Int {
        dailyGoal - caloriesEaten
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week Date Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        WeekDayButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            action: { selectedDate = date }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Selected Day Content
            VStack(spacing: 0) {
                // Calorie Summary Header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dateTitle(for: selectedDate))
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
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Add Food") {
                            showingAddFood = true
                        }
                        .buttonStyle(.bordered)
                        
                        if !selectedDayItems.isEmpty {
                            Button("Copy Day") {
                                showingCopyDayAlert = true
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Food Items List
                if selectedDayItems.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No meals planned")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Tap 'Add Food' to plan meals for \(dayName(for: selectedDate))")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(selectedDayItems, id: \.id) { item in
                            WeeklyFoodItemRow(
                                item: item,
                                selectedDate: selectedDate,
                                onToggle: { toggleItemStatus(item) }
                            )
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView(targetDate: selectedDate)
        }
        .alert("Copy Day", isPresented: $showingCopyDayAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Choose Day") {
                showingCopyConfirmation = true
            }
        } message: {
            Text("Copy all meals from \(dayName(for: selectedDate)) to another day?")
        }
        .sheet(isPresented: $showingCopyConfirmation) {
            CopyDaySheet(
                sourceDate: selectedDate,
                weekDates: currentWeekDates,
                onCopy: copyDay
            )
        }
    }
    
    private func dateTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today's Progress"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow's Plan"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday's Meals"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE's Plan"
            return formatter.string(from: date)
        }
    }
    
    private func dayName(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
    
    private func toggleItemStatus(_ item: FoodItem) {
        // Only allow toggling to "eaten" for today and past days
        let calendar = Calendar.current
        if calendar.compare(selectedDate, to: Date(), toGranularity: .day) != .orderedDescending {
            item.toggleStatus()
            
            do {
                try modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Error updating item status: \(error)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(selectedDayItems[index])
        }
        
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error deleting items: \(error)")
        }
    }
    
    private func copyDay(to destinationDate: Date) {
        // Copy all items from selected date to destination date
        for item in selectedDayItems {
            let copiedItem = FoodItem(
                name: item.name,
                calories: item.calories,
                date: Calendar.current.startOfDay(for: destinationDate)
            )
            // Status is already set to .planned by default in FoodItem init
            
            modelContext.insert(copiedItem)
        }
        
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            selectedDate = destinationDate // Switch to copied day
        } catch {
            print("Error copying day: \(error)")
        }
    }
}

struct WeekDayButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(dayNumberFormatter.string(from: date))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 50, height: 60)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeeklyFoodItemRow: View {
    let item: FoodItem
    let selectedDate: Date
    let onToggle: () -> Void
    
    private var canToggleStatus: Bool {
        // Can only toggle to "eaten" for today and past days
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day) != .orderedDescending
    }
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.status.systemImage)
                    .font(.title2)
                    .foregroundColor(item.status == .eaten ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canToggleStatus)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(canToggleStatus ? item.status.displayName : "Planned")
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
        .opacity(canToggleStatus ? 1.0 : 0.7)
    }
}

struct CopyDaySheet: View {
    let sourceDate: Date
    let weekDates: [Date]
    let onCopy: (Date) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDestination: Date?
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Copy to which day?")) {
                    ForEach(weekDates, id: \.self) { date in
                        if !Calendar.current.isDate(date, inSameDayAs: sourceDate) {
                            Button(action: {
                                selectedDestination = date
                            }) {
                                HStack {
                                    Text(dayFormatter.string(from: date))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if let selected = selectedDestination,
                                       Calendar.current.isDate(selected, inSameDayAs: date) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Copy Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy") {
                        if let destination = selectedDestination {
                            onCopy(destination)
                            dismiss()
                        }
                    }
                    .disabled(selectedDestination == nil)
                }
            }
        }
    }
}

#Preview {
    WeeklyPlannerView()
        .modelContainer(for: [FoodItem.self, FoodHistory.self], inMemory: true)
}