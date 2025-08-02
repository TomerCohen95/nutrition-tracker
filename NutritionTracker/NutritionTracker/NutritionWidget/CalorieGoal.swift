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
        
        let applicableGoals = goals.filter {
            let goalDate = calendar.startOfDay(for: $0.effectiveDate)
            return goalDate <= targetDate
        }
        let mostRecentGoal = applicableGoals.max(by: { $0.effectiveDate < $1.effectiveDate })
        return mostRecentGoal?.goalCalories ?? 2000 // Default to 2000 if no goal set
    }
}