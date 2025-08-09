//
//  NutritionWidget.swift
//  NutritionWidget
//
//  Home screen widget (Deliverable 3)
//

import AppIntents
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

struct NutritionWidget: Widget {
    let kind: String = "NutritionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NutritionWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nutrition Tracker")
        .description("See your daily calorie progress and food items.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            caloriesEaten: 1234,
            caloriesPlanned: 1584,
            dailyGoal: 2000,
            foodItems: [
                (UUID().uuidString, "Apple", FoodItem.FoodStatus.eaten, 95),
                (UUID().uuidString, "Sandwich", FoodItem.FoodStatus.planned, 350),
                (UUID().uuidString, "Salad", FoodItem.FoodStatus.eaten, 150),
            ],
            allItems: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            caloriesEaten: 1234,
            caloriesPlanned: 1584,
            dailyGoal: 2000,
            foodItems: [
                (UUID().uuidString, "Apple", FoodItem.FoodStatus.eaten, 95),
                (UUID().uuidString, "Sandwich", FoodItem.FoodStatus.planned, 350),
                (UUID().uuidString, "Salad", FoodItem.FoodStatus.eaten, 150),
            ],
            allItems: []
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let entry = fetchCurrentData(for: currentDate)

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func fetchCurrentData(for date: Date) -> SimpleEntry {
        // Create model container with App Group
        let schema = Schema([FoodItem.self, FoodHistory.self, CalorieGoal.self])
        let modelConfiguration = ModelConfiguration(
            "NutritionTracker",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.tomercode.nutritiontracker")
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)

            // Fetch today's items
            let today = Calendar.current.startOfDay(for: date)
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

            let descriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate { item in
                    item.date >= today && item.date < tomorrow
                },
                sortBy: [SortDescriptor(\.createdAt)]
            )

            let todaysItems = try context.fetch(descriptor)

            // Calculate calories eaten
            let caloriesEaten =
                todaysItems
                .filter { $0.status == FoodItem.FoodStatus.eaten }
                .reduce(0) { $0 + $1.calories }

            // Calculate planned calories (including both eaten and planned items)
            let caloriesPlanned =
                todaysItems
                .reduce(0) { $0 + $1.calories }

            // Fetch current calorie goal
            let goalDescriptor = FetchDescriptor<CalorieGoal>(
                sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
            )
            let calorieGoals = try context.fetch(goalDescriptor)
            let currentGoal = CalorieGoal.currentGoal(for: date, from: calorieGoals)

            // Prepare food items for display with more items for larger widgets
            let displayItems = todaysItems.map { item in
                (item.id.uuidString, item.name, item.status, item.calories)
            }

            return SimpleEntry(
                date: date,
                caloriesEaten: caloriesEaten,
                caloriesPlanned: caloriesPlanned,
                dailyGoal: currentGoal,
                foodItems: displayItems,
                allItems: todaysItems
            )

        } catch {
            print("Widget error fetching data: \(error)")
            // Return empty state on error
            return SimpleEntry(
                date: date,
                caloriesEaten: 0,
                caloriesPlanned: 0,
                dailyGoal: 2000,
                foodItems: [],
                allItems: []
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let caloriesEaten: Int
    let caloriesPlanned: Int
    let dailyGoal: Int
    let foodItems: [(String, String, FoodItem.FoodStatus, Int)]  // ID, Name, Status, Calories
    let allItems: [FoodItem]
}

struct NutritionWidgetEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .systemExtraLarge:
            ExtraLargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry

    private var remainingCalories: Int {
        entry.dailyGoal - entry.caloriesEaten
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.primary)
                Text("Nutrition")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }

            Spacer()

            // Calories
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.caloriesEaten)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("/ \(entry.dailyGoal) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Remaining/Over
            if remainingCalories >= 0 {
                Text("\(remainingCalories) left")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("\(abs(remainingCalories)) over")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            // Progress bar
            ProgressView(
                value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                total: Double(entry.dailyGoal)
            )
            .tint(remainingCalories >= 0 ? .green : .red)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry

    private var remainingCalories: Int {
        entry.dailyGoal - entry.caloriesEaten
    }

    private var remainingPlannedCalories: Int {
        entry.dailyGoal - entry.caloriesPlanned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.primary)
                    .font(.system(size: 12))
                Text("Today's Nutrition")
                    .font(.system(size: 14, weight: .medium))
                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    // Eaten progress
                    HStack(spacing: 2) {
                        Text("Eaten:")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text("\(entry.caloriesEaten) / \(entry.dailyGoal)")
                            .font(.system(size: 10, weight: .medium))
                    }

                    // Planned progress
                    HStack(spacing: 2) {
                        Text("Planned:")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text("\(entry.caloriesPlanned) / \(entry.dailyGoal)")
                            .font(.system(size: 10, weight: .medium))
                    }
                }
            }

            // Dual progress bars
            VStack(spacing: 2) {
                // Eaten progress bar
                HStack {
                    Text("Eaten")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    ProgressView(
                        value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                        total: Double(entry.dailyGoal)
                    )
                    .tint(remainingCalories >= 0 ? .green : .red)
                    .scaleEffect(y: 0.6)
                    if remainingCalories >= 0 {
                        Text("\(remainingCalories) left")
                            .font(.system(size: 9))
                            .foregroundColor(.green)
                    } else {
                        Text("\(abs(remainingCalories)) over")
                            .font(.system(size: 9))
                            .foregroundColor(.red)
                    }
                }

                // Planned progress bar
                HStack {
                    Text("Planned")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .leading)
                    ProgressView(
                        value: min(Double(entry.caloriesPlanned), Double(entry.dailyGoal)),
                        total: Double(entry.dailyGoal)
                    )
                    .tint(remainingPlannedCalories >= 0 ? .blue : .orange)
                    .scaleEffect(y: 0.6)
                    if remainingPlannedCalories >= 0 {
                        Text("\(remainingPlannedCalories) left")
                            .font(.system(size: 9))
                            .foregroundColor(.blue)
                    } else {
                        Text("\(abs(remainingPlannedCalories)) over")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }
                }
            }

            // Food items
            if entry.foodItems.isEmpty {
                Text("No food items today")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    // Show only first 3 items to prevent overflow with more compact layout
                    ForEach(Array(entry.foodItems.prefix(3).enumerated()), id: \.offset) {
                        index, item in
                        HStack(spacing: 4) {
                            Button(intent: ToggleFoodStatusIntent(foodItemId: item.0)) {
                                Image(systemName: item.2.systemImage)
                                    .font(.system(size: 10))
                                    .foregroundColor(
                                        item.2 == FoodItem.FoodStatus.eaten ? .green : .gray)
                            }

                            Text(item.1)
                                .font(.system(size: 8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .truncationMode(.tail)

                            Spacer()

                            Text("\(item.3)")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 1)
                    }

                    // Show "and X more" if there are additional items
                    if entry.foodItems.count > 3 {
                        Text("+\(entry.foodItems.count - 3) more")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 1)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}

#Preview(as: .systemSmall) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: Date.now,
        caloriesEaten: 1234,
        caloriesPlanned: 1584,
        dailyGoal: 2000,
        foodItems: [
            ("1", "Apple", FoodItem.FoodStatus.eaten, 95),
            ("2", "Sandwich", FoodItem.FoodStatus.planned, 350),
        ],
        allItems: []
    )
}

#Preview(as: .systemMedium) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: Date.now,
        caloriesEaten: 1245,
        caloriesPlanned: 1945,
        dailyGoal: 2000,
        foodItems: [
            ("1", "Apple", FoodItem.FoodStatus.eaten, 95),
            ("2", "Sandwich", FoodItem.FoodStatus.planned, 350),
            ("3", "Salad", FoodItem.FoodStatus.eaten, 120),
            ("4", "Yogurt", FoodItem.FoodStatus.eaten, 150),
        ],
        allItems: []
    )
}

struct LargeWidgetView: View {
    let entry: SimpleEntry

    private var remainingCalories: Int {
        entry.dailyGoal - entry.caloriesEaten
    }

    private var remainingPlannedCalories: Int {
        entry.dailyGoal - entry.caloriesPlanned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Nutrition")
                        .font(.system(size: 16, weight: .medium))

                    HStack(alignment: .bottom, spacing: 3) {
                        Text("\(entry.caloriesEaten)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("/ \(entry.dailyGoal) kcal")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    // Eaten stats
                    VStack(alignment: .trailing) {
                        if remainingCalories >= 0 {
                            Text("\(remainingCalories) left")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text("\(abs(remainingCalories)) over")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }

                        Text("eaten")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }

                    // Planned stats
                    VStack(alignment: .trailing) {
                        if remainingPlannedCalories >= 0 {
                            Text("\(remainingPlannedCalories) left")
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        } else {
                            Text("\(abs(remainingPlannedCalories)) over")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }

                        Text("planned")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Dual progress bars
            VStack(spacing: 3) {
                // Eaten progress bar
                HStack {
                    Text("Eaten")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    ProgressView(
                        value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                        total: Double(entry.dailyGoal)
                    )
                    .tint(remainingCalories >= 0 ? .green : .red)
                    .scaleEffect(y: 0.7)
                }

                // Planned progress bar
                HStack {
                    Text("Planned")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    ProgressView(
                        value: min(Double(entry.caloriesPlanned), Double(entry.dailyGoal)),
                        total: Double(entry.dailyGoal)
                    )
                    .tint(remainingPlannedCalories >= 0 ? .blue : .orange)
                    .scaleEffect(y: 0.7)
                }
            }

            // Food items grid
            if entry.foodItems.isEmpty {
                VStack {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No food items today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                    ForEach(Array(entry.foodItems.prefix(8).enumerated()), id: \.offset) {
                        index, item in
                        HStack {
                            Button(intent: ToggleFoodStatusIntent(foodItemId: item.0)) {
                                Image(systemName: item.2.systemImage)
                                    .font(.system(size: 14))
                                    .foregroundColor(
                                        item.2 == FoodItem.FoodStatus.eaten ? .green : .gray)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.1)
                                    .font(.system(size: 13))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)

                                Text("\(item.3) kcal")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct ExtraLargeWidgetView: View {
    let entry: SimpleEntry

    private var remainingCalories: Int {
        entry.dailyGoal - entry.caloriesEaten
    }

    private var remainingPlannedCalories: Int {
        entry.dailyGoal - entry.caloriesPlanned
    }

    private var eatenItems: [(String, String, FoodItem.FoodStatus, Int)] {
        entry.foodItems.filter { $0.2 == FoodItem.FoodStatus.eaten }
    }

    private var plannedItems: [(String, String, FoodItem.FoodStatus, Int)] {
        entry.foodItems.filter { $0.2 == FoodItem.FoodStatus.planned }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with comprehensive stats
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Nutrition Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Eaten calories
                    HStack(alignment: .bottom, spacing: 6) {
                        Text("\(entry.caloriesEaten)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)

                        Text("/ \(entry.dailyGoal) kcal eaten")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    // Progress bars
                    VStack(spacing: 4) {
                        // Eaten progress bar
                        HStack {
                            Text("Eaten")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            ProgressView(
                                value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                                total: Double(entry.dailyGoal)
                            )
                            .tint(remainingCalories >= 0 ? .green : .red)
                            .scaleEffect(y: 1.5)
                        }

                        // Planned progress bar
                        HStack {
                            Text("Planned")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            ProgressView(
                                value: min(Double(entry.caloriesPlanned), Double(entry.dailyGoal)),
                                total: Double(entry.dailyGoal)
                            )
                            .tint(remainingPlannedCalories >= 0 ? .blue : .orange)
                            .scaleEffect(y: 1.5)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 12) {
                    // Eaten stats
                    VStack(alignment: .trailing) {
                        if remainingCalories >= 0 {
                            Text("\(remainingCalories)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("calories left to eat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(abs(remainingCalories))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("calories over eaten")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Planned stats
                    VStack(alignment: .trailing) {
                        Text("\(entry.caloriesPlanned)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("total planned calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .trailing) {
                        Text("\(eatenItems.count)/\(entry.foodItems.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("items completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Two-column layout for eaten and planned items
            HStack(alignment: .top, spacing: 20) {
                // Eaten items
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Eaten (\(eatenItems.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(eatenItems.reduce(0) { $0 + $1.3 }) kcal")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    if eatenItems.isEmpty {
                        Text("No items eaten yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(eatenItems.prefix(6).enumerated()), id: \.offset) {
                            index, item in
                            HStack {
                                Button(intent: ToggleFoodStatusIntent(foodItemId: item.0)) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.1)
                                        .font(.body)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                    Text("\(item.3) kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Planned items
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                        Text("Planned (\(plannedItems.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(plannedItems.reduce(0) { $0 + $1.3 }) kcal")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    if plannedItems.isEmpty {
                        Text("No items planned")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(plannedItems.prefix(6).enumerated()), id: \.offset) {
                            index, item in
                            HStack {
                                Button(intent: ToggleFoodStatusIntent(foodItemId: item.0)) {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.1)
                                        .font(.body)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                    Text("\(item.3) kcal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview(as: .systemSmall) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: Date.now,
        caloriesEaten: 1234,
        caloriesPlanned: 1584,
        dailyGoal: 2000,
        foodItems: [
            ("1", "Apple", FoodItem.FoodStatus.eaten, 95),
            ("2", "Sandwich", FoodItem.FoodStatus.planned, 350),
        ],
        allItems: []
    )
}

#Preview(as: .systemMedium) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: Date.now,
        caloriesEaten: 1245,
        caloriesPlanned: 1945,
        dailyGoal: 2000,
        foodItems: [
            ("1", "Apple", FoodItem.FoodStatus.eaten, 95),
            ("2", "Sandwich", FoodItem.FoodStatus.planned, 350),
            ("3", "Salad", FoodItem.FoodStatus.eaten, 120),
            ("4", "Yogurt", FoodItem.FoodStatus.eaten, 150),
            ("5", "Chicken Breast", FoodItem.FoodStatus.planned, 200),
            ("6", "Rice", FoodItem.FoodStatus.planned, 150),
            ("7", "Broccoli", FoodItem.FoodStatus.eaten, 30),
            ("8", "Almonds", FoodItem.FoodStatus.planned, 160),
        ],
        allItems: []
    )
}

#Preview(as: .systemLarge) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: Date.now,
        caloriesEaten: 1400,
        caloriesPlanned: 2060,
        dailyGoal: 2000,
        foodItems: [
            ("1", "Apple", FoodItem.FoodStatus.eaten, 95),
            ("2", "Sandwich", FoodItem.FoodStatus.planned, 350),
            ("3", "Salad", FoodItem.FoodStatus.eaten, 120),
            ("4", "Yogurt", FoodItem.FoodStatus.eaten, 150),
            ("5", "Chicken Breast", FoodItem.FoodStatus.planned, 200),
            ("6", "Rice", FoodItem.FoodStatus.planned, 150),
            ("7", "Broccoli", FoodItem.FoodStatus.eaten, 30),
            ("8", "Almonds", FoodItem.FoodStatus.planned, 160),
        ],
        allItems: []
    )
}

#Preview(as: .systemExtraLarge) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: Date.now,
        caloriesEaten: 1600,
        caloriesPlanned: 2375,
        dailyGoal: 2200,
        foodItems: [
            ("1", "Apple", FoodItem.FoodStatus.eaten, 95),
            ("2", "Sandwich", FoodItem.FoodStatus.eaten, 350),
            ("3", "Salad", FoodItem.FoodStatus.eaten, 120),
            ("4", "Yogurt", FoodItem.FoodStatus.eaten, 150),
            ("5", "Chicken Breast", FoodItem.FoodStatus.planned, 200),
            ("6", "Rice", FoodItem.FoodStatus.planned, 150),
            ("7", "Broccoli", FoodItem.FoodStatus.eaten, 30),
            ("8", "Almonds", FoodItem.FoodStatus.planned, 160),
            ("9", "Banana", FoodItem.FoodStatus.planned, 100),
            ("10", "Greek Yogurt", FoodItem.FoodStatus.planned, 120),
        ],
        allItems: []
    )
}
