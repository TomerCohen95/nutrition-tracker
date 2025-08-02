//
//  CopyToDaysView.swift
//  NutritionTracker
//
//  Day selection view for copying food items to specific days
//

import SwiftUI
import SwiftData
import WidgetKit

struct CopyToDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let foodItem: FoodItem
    
    @State private var selectedDates: Set<Date> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var currentWeekOffset = 0
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.paddingL) {
                // Food Item Preview
                VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                    Text("Copy Food Item")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: AppTheme.paddingM) {
                        VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                            Text(foodItem.name)
                                .font(AppTheme.bodyFont)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("\(foodItem.calories) kcal")
                                .font(AppTheme.smallFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text("\(foodItem.calories)")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, AppTheme.paddingS)
                            .padding(.vertical, AppTheme.paddingXS)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.radiusS)
                                    .fill(AppTheme.lightGreen)
                            )
                    }
                }
                .padding(AppTheme.paddingM)
                .cardStyle()
                
                // Week Navigation
                HStack {
                    Button(action: { currentWeekOffset -= 1 }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                    
                    Spacer()
                    
                    Text(weekRangeText)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { currentWeekOffset += 1 }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)
                
                // Day Selection Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.paddingS) {
                    ForEach(weekDays, id: \.self) { date in
                        DaySelectionCard(
                            date: date,
                            isSelected: selectedDates.contains(date),
                            isToday: calendar.isDateInToday(date),
                            onTap: { toggleDateSelection(date) }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: AppTheme.paddingM) {
                    Button(action: copyToSelectedDays) {
                        Text("Copy to \(selectedDates.count) day\(selectedDates.count == 1 ? "" : "s")")
                            .font(AppTheme.bodyFont)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedDates.isEmpty)
                    .opacity(selectedDates.isEmpty ? 0.6 : 1.0)
                    
                    Button("Select All Week") {
                        selectAllWeekDays()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, AppTheme.paddingM)
            }
            .padding(.vertical, AppTheme.paddingM)
            .background(AppTheme.secondaryBackground)
            .navigationTitle("Copy to Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .alert("Success", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekDays: [Date] {
        let today = Date()
        let weekOffset = currentWeekOffset * 7
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let targetWeekStart = calendar.date(byAdding: .day, value: weekOffset, to: startOfWeek) ?? startOfWeek
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: targetWeekStart)
        }
    }
    
    private var weekRangeText: String {
        guard let firstDay = weekDays.first, let lastDay = weekDays.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startText = formatter.string(from: firstDay)
        let endText = formatter.string(from: lastDay)
        
        return "\(startText) - \(endText)"
    }
    
    // MARK: - Functions
    
    private func toggleDateSelection(_ date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        if selectedDates.contains(startOfDay) {
            selectedDates.remove(startOfDay)
        } else {
            selectedDates.insert(startOfDay)
        }
    }
    
    private func selectAllWeekDays() {
        let weekStartDates = weekDays.map { calendar.startOfDay(for: $0) }
        selectedDates = Set(weekStartDates)
    }
    
    private func copyToSelectedDays() {
        guard !selectedDates.isEmpty else { return }
        
        var copiedCount = 0
        
        for targetDate in selectedDates {
            // Create a new food item for each selected date
            let newFoodItem = FoodItem(name: foodItem.name, calories: foodItem.calories, date: targetDate)
            newFoodItem.status = .planned // Always start as planned
            
            modelContext.insert(newFoodItem)
            copiedCount += 1
        }
        
        do {
            try modelContext.save()
            
            // Refresh widget after copying
            WidgetCenter.shared.reloadAllTimelines()
            
            alertMessage = "Successfully copied \"\(foodItem.name)\" to \(copiedCount) day\(copiedCount == 1 ? "" : "s")!"
            showingAlert = true
        } catch {
            alertMessage = "Failed to copy food item: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct DaySelectionCard: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(AppTheme.smallFont)
                    .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                
                Text("\(calendar.component(.day, from: date))")
                    .font(AppTheme.bodyFont)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusS)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusS)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppTheme.primaryGreen
        } else {
            return AppTheme.cardBackground
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return AppTheme.primaryGreen
        } else {
            return Color.clear
        }
    }
}

#Preview {
    let sampleItem = FoodItem(name: "Apple", calories: 95)
    CopyToDaysView(foodItem: sampleItem)
        .modelContainer(for: FoodItem.self, inMemory: true)
}