//
//  AddFoodView.swift
//  NutritionTracker
//
//  Screen for adding new food items (Deliverable 1)
//

import SwiftUI
import SwiftData
import WidgetKit
import Foundation

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Use the new FoodHistoryManager instead of SwiftData @Query
    @ObservedObject private var historyManager = FoodHistoryManager.shared
    
    let targetDate: Date
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var proteinGrams = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var searchResults: [FoodHistoryItem] = []
    @State private var showSearchDropdown = false
    @FocusState private var isNameFieldFocused: Bool
    
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
                            
                            if !historyManager.history.isEmpty {
                                Text("Tap to use")
                                    .font(AppTheme.smallFont)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        
                        if !historyManager.history.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.paddingM) {
                                    ForEach(Array(historyManager.getMostRecent(limit: 10)), id: \.id) { historyItem in
                                        Button(action: {
                                            selectFromHistory(historyItem)
                                        }) {
                                            VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                                                Text(historyItem.name)
                                                    .font(AppTheme.captionFont)
                                                    .foregroundColor(AppTheme.textPrimary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Text("\(historyItem.calories) kcal • \(historyItem.proteinGrams)g")
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
                        
                        // History count indicator
                        Text("History: \(historyManager.history.count) items")
                            .font(AppTheme.smallFont)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.top, AppTheme.paddingXS)
                    }
                    .padding(.horizontal, AppTheme.paddingM)
                    
                    
                    // Food Details Card
                    VStack(spacing: AppTheme.paddingL) {
                        VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                            Text("Food Details")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            VStack(spacing: AppTheme.paddingM) {
                                // Food Name with Search Dropdown
                                VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                                    Text("Food Name")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    ZStack(alignment: .top) {
                                        VStack(spacing: 0) {
                                            TextField("Enter food name", text: $foodName)
                                                .font(AppTheme.bodyFont)
                                                .padding(AppTheme.paddingM)
                                                .background(AppTheme.secondaryBackground)
                                                .cornerRadius(AppTheme.radiusS)
                                                .focused($isNameFieldFocused)
                                                .onChange(of: foodName) { _, newValue in
                                                    performSearch(query: newValue)
                                                }
                                            
                                            // Search Results Dropdown
                                            if showSearchDropdown && !searchResults.isEmpty {
                                                VStack(spacing: 0) {
                                                    ForEach(searchResults, id: \.id) { item in
                                                        Button(action: {
                                                            selectSearchResult(item)
                                                        }) {
                                                            HStack {
                                                                Text(item.name)
                                                                    .font(AppTheme.bodyFont)
                                                                    .foregroundColor(AppTheme.textPrimary)
                                                                Spacer()
                                                                Text("\(item.calories) kcal • \(item.proteinGrams)g")
                                                                    .font(AppTheme.captionFont)
                                                                    .foregroundColor(AppTheme.primaryGreen)
                                                                    .fontWeight(.medium)
                                                            }
                                                            .padding(.horizontal, AppTheme.paddingM)
                                                            .padding(.vertical, AppTheme.paddingS)
                                                            .background(AppTheme.cardBackground)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        
                                                        if item.id != searchResults.last?.id {
                                                            Divider()
                                                                .background(AppTheme.textSecondary.opacity(0.2))
                                                        }
                                                    }
                                                }
                                                .background(AppTheme.cardBackground)
                                                .cornerRadius(AppTheme.radiusS)
                                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            }
                                        }
                                    }
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

                                VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                                    Text("Protein")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)

                                    TextField("Enter protein in grams", text: $proteinGrams)
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
                        .disabled(foodName.isEmpty || calories.isEmpty || proteinGrams.isEmpty)
                        .opacity(foodName.isEmpty || calories.isEmpty || proteinGrams.isEmpty ? 0.6 : 1.0)
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
            .onAppear {
                print("📱 AddFoodView appeared - History count: \(historyManager.history.count)")
                // Refresh history when view appears
                historyManager.loadHistory()
            }
        }
    }
    
    private func addFoodItem() {
        print("🍎 Adding food item: \(foodName) - \(calories) kcal - \(proteinGrams)g protein")
        
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

        guard let proteinValue = Int(proteinGrams), proteinValue >= 0 else {
            alertMessage = "Please enter a valid number of protein grams"
            showingAlert = true
            return
        }
        
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create and save food item with target date
        let foodItem = FoodItem(
            name: trimmedName,
            calories: calorieValue,
            proteinGrams: proteinValue
        )
        
        // Set the date to the target date (for weekly planning)
        foodItem.date = Calendar.current.startOfDay(for: targetDate)
        
        modelContext.insert(foodItem)
        
        do {
            try modelContext.save()
            print("✅ Food item saved successfully")
            
            // Add to food history using the new manager
            historyManager.addOrUpdate(
                name: trimmedName,
                calories: calorieValue,
                proteinGrams: proteinValue
            )
            
            // Force widget refresh immediately after saving
            WidgetCenter.shared.reloadAllTimelines()
            
            dismiss()
        } catch {
            print("❌ Failed to save food item: \(error)")
            alertMessage = "Failed to save food item: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - History Functions
    
    private func selectFromHistory(_ historyItem: FoodHistoryItem) {
        foodName = historyItem.name
        calories = String(historyItem.calories)
        proteinGrams = String(historyItem.proteinGrams)
        showSearchDropdown = false
        
        // Update usage count and last used date
        historyManager.markAsUsed(historyItem)
        print("✅ Selected from history: \(historyItem.name)")
    }
    
    // MARK: - Search Functions
    
    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchResults = []
            showSearchDropdown = false
        } else {
            searchResults = historyManager.search(query: trimmed, limit: 5)
            showSearchDropdown = !searchResults.isEmpty && isNameFieldFocused
        }
    }
    
    private func selectSearchResult(_ item: FoodHistoryItem) {
        foodName = item.name
        calories = String(item.calories)
        proteinGrams = String(item.proteinGrams)
        showSearchDropdown = false
        isNameFieldFocused = false
        
        // Update usage count and last used date
        historyManager.markAsUsed(item)
        print("✅ Selected from search: \(item.name)")
    }
}

#Preview {
    AddFoodView()
        .modelContainer(for: [FoodItem.self, CalorieGoal.self], inMemory: true)
}
