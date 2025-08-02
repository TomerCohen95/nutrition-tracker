import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CalorieGoal.effectiveDate, order: .reverse) var calorieGoals: [CalorieGoal]
    
    @State private var newCalorieGoal: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var currentGoal: Int {
        CalorieGoal.currentGoal(for: Date(), from: calorieGoals)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.paddingL) {
                VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                    Text("Current Daily Goal")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack {
                        Text("\(currentGoal)")
                            .font(AppTheme.titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Text("calories")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.radiusM)
                
                VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                    Text("Set New Daily Goal")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    TextField("Enter calories (e.g., 2000)", text: $newCalorieGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("Changes will apply from today forward")
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Button(action: updateCalorieGoal) {
                        Text("Update Goal")
                            .font(AppTheme.bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(AppTheme.radiusM)
                    }
                    .disabled(newCalorieGoal.isEmpty)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.radiusM)
                
                if !calorieGoals.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.paddingM) {
                        Text("Goal History")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        ForEach(calorieGoals.prefix(5), id: \.effectiveDate) { goal in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(goal.goalCalories) calories")
                                        .font(AppTheme.bodyFont)
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text("From \(goal.effectiveDate, formatter: dateFormatter)")
                                        .font(AppTheme.captionFont)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                if goal == calorieGoals.first {
                                    Text("Current")
                                        .font(AppTheme.captionFont)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.primaryGreen.opacity(0.2))
                                        .foregroundColor(AppTheme.primaryGreen)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.radiusM)
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.secondaryBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Goal Updated", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            newCalorieGoal = String(currentGoal)
        }
    }
    
    private func updateCalorieGoal() {
        guard let calories = Int(newCalorieGoal), calories > 0 else {
            alertMessage = "Please enter a valid number of calories"
            showingAlert = true
            return
        }
        
        let newGoal = CalorieGoal(goalCalories: calories, effectiveDate: Date())
        modelContext.insert(newGoal)
        
        do {
            try modelContext.save()
            
            // Force refresh widgets after calorie goal change
            WidgetCenter.shared.reloadAllTimelines()
            
            alertMessage = "Your daily calorie goal has been updated to \(calories) calories"
            showingAlert = true
            
            // Debug: Print the new goal to verify it was saved
            print("CalorieGoal saved: \(calories) calories effective from \(Date())")
        } catch {
            print("Error saving CalorieGoal: \(error)")
            alertMessage = "Failed to save calorie goal. Please try again."
            showingAlert = true
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    SettingsView()
        .modelContainer(for: [CalorieGoal.self])
}