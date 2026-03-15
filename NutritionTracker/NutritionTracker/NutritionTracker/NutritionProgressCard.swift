import SwiftUI

struct NutritionProgressCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let dailyGoal: Int
    let dailyProteinGoal: Int
    let caloriesEaten: Int
    let caloriesPlanned: Int
    let proteinEaten: Int
    let proteinPlanned: Int
    let remainingCalories: Int
    let remainingPlannedCalories: Int
    let remainingProtein: Int
    let remainingPlannedProtein: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: AppTheme.paddingS) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Goal \(formatted(dailyGoal)) kcal • Protein \(dailyProteinGoal)g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer(minLength: AppTheme.paddingS)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("Remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    Text("\(formatted(remainingCalories)) kcal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(
                            remainingCalories >= 0
                                ? AppTheme.primaryGreen : AppTheme.accentOrange
                        )
                }
            }

            NutritionMetricSection(
                title: "Calories",
                eatenLabel: formatted(caloriesEaten),
                plannedLabel: formatted(caloriesPlanned),
                eatenValue: Double(min(caloriesEaten, dailyGoal)),
                plannedValue: Double(min(caloriesPlanned, dailyGoal)),
                totalValue: Double(max(dailyGoal, 1)),
                eatenTint: remainingCalories >= 0 ? AppTheme.primaryGreen : AppTheme.accentOrange,
                plannedTint: remainingPlannedCalories >= 0 ? .blue : .orange
            )

            NutritionMetricSection(
                title: "Protein",
                eatenLabel: "\(proteinEaten)g",
                plannedLabel: "\(proteinPlanned)g",
                eatenValue: Double(min(proteinEaten, dailyProteinGoal)),
                plannedValue: Double(min(proteinPlanned, dailyProteinGoal)),
                totalValue: Double(max(dailyProteinGoal, 1)),
                eatenTint: remainingProtein >= 0 ? AppTheme.primaryGreen : AppTheme.accentOrange,
                plannedTint: remainingPlannedProtein >= 0 ? .blue : .orange
            )
        }
        .padding(14)
        .cardStyle(backgroundColor: AppTheme.adaptiveLightGreen(colorScheme))
    }

    private func formatted(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
}

private struct NutritionMetricSection: View {
    let title: String
    let eatenLabel: String
    let plannedLabel: String
    let eatenValue: Double
    let plannedValue: Double
    let totalValue: Double
    let eatenTint: Color
    let plannedTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            NutritionProgressRow(
                label: "Eaten",
                valueLabel: eatenLabel,
                value: eatenValue,
                total: totalValue,
                tint: eatenTint
            )

            NutritionProgressRow(
                label: "Planned",
                valueLabel: plannedLabel,
                value: plannedValue,
                total: totalValue,
                tint: plannedTint
            )
        }
    }
}

private struct NutritionProgressRow: View {
    let label: String
    let valueLabel: String
    let value: Double
    let total: Double
    let tint: Color

    var body: some View {
        HStack(spacing: AppTheme.paddingS) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(tint)
                .frame(width: 48, alignment: .leading)

            ProgressView(value: value, total: total)
                .tint(tint)
                .scaleEffect(y: 0.78)

            Text(valueLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 52, alignment: .trailing)
        }
    }
}
