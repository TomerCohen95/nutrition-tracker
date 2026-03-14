import Foundation
import SwiftData

@Model
class CalorieGoal {
    var goalCalories: Int
    var goalProteinGrams: Int = 200
    var effectiveDate: Date
    
    init(goalCalories: Int, goalProteinGrams: Int = 200, effectiveDate: Date = Date()) {
        self.goalCalories = goalCalories
        self.goalProteinGrams = goalProteinGrams
        self.effectiveDate = effectiveDate
    }
    
    /// Get the current calorie goal for a given date
    static func currentGoal(for date: Date, from goals: [CalorieGoal]) -> Int {
        currentGoalRecord(for: date, from: goals)?.goalCalories ?? 2500
    }

    static func currentProteinGoal(for date: Date, from goals: [CalorieGoal]) -> Int {
        currentGoalRecord(for: date, from: goals)?.goalProteinGrams ?? 200
    }

    static func currentGoalRecord(for date: Date, from goals: [CalorieGoal]) -> CalorieGoal? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Filter goals that are effective on or before the target date
        let applicableGoals = goals.filter {
            let goalDate = calendar.startOfDay(for: $0.effectiveDate)
            return goalDate <= targetDate
        }
        
        // Sort by effectiveDate in descending order and take the first (most recent)
        return applicableGoals.sorted { $0.effectiveDate > $1.effectiveDate }.first
    }
}
