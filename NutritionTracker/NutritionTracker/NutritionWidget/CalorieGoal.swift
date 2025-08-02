import Foundation
import SwiftData

@Model
class CalorieGoal {
    var goalCalories: Int
    var effectiveDate: Date
    
    init(goalCalories: Int, effectiveDate: Date = Date()) {
        self.goalCalories = goalCalories
        self.effectiveDate = effectiveDate
    }
    
    /// Get the current calorie goal for a given date
    static func currentGoal(for date: Date, from goals: [CalorieGoal]) -> Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Filter goals that are effective on or before the target date
        let applicableGoals = goals.filter {
            let goalDate = calendar.startOfDay(for: $0.effectiveDate)
            return goalDate <= targetDate
        }
        
        // Sort by effectiveDate in descending order and take the first (most recent)
        let mostRecentGoal = applicableGoals.sorted { $0.effectiveDate > $1.effectiveDate }.first
        return mostRecentGoal?.goalCalories ?? 2000 // Default to 2000 if no goal set
    }
}