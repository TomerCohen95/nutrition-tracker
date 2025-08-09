//
//  NutritionWidget.swift
//  NutritionWidget
//
//  Home screen widget (Deliverable 3)
//

import AppIntents
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
            dailyGoal: 2500,
            foodItems: [
                (UUID().uuidString, "Apple", .eaten, 95),
                (UUID().uuidString, "Sandwich", .planned, 350),
                (UUID().uuidString, "Salad", .eaten, 150),
            ],
            allItems: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(
            date: Date(),
            caloriesEaten: 1234,
            dailyGoal: 2500,
            foodItems: [
                (UUID().uuidString, "Apple", .eaten, 95),
                (UUID().uuidString, "Sandwich", .planned, 350),
                (UUID().uuidString, "Salad", .eaten, 150),
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
                .filter { $0.status == .eaten }
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
                dailyGoal: 2500,
                foodItems: [],
                allItems: []
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let caloriesEaten: Int
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.primary)
                Text("Today's Nutrition")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()

                VStack(alignment: .trailing) {
                    Text("\(entry.caloriesEaten) / \(entry.dailyGoal)")
                        .font(.caption)
                        .fontWeight(.medium)

                    if remainingCalories >= 0 {
                        Text("\(remainingCalories) left")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("\(abs(remainingCalories)) over")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }

            // Progress bar
            ProgressView(
                value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                total: Double(entry.dailyGoal)
            )
            .tint(remainingCalories >= 0 ? .green : .red)

            // Food items
            if entry.foodItems.isEmpty {
                Text("No food items today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entry.foodItems.indices, id: \.self) { index in
                        let item = entry.foodItems[index]
                        HStack {
                            Button(intent: ToggleFoodStatusIntent(foodItemId: item.0)) {
                                Image(systemName: item.2.systemImage)
                                    .font(.caption)
                                    .foregroundColor(item.2 == .eaten ? .green : .gray)
                            }

                            Text(item.1)
                                .font(.caption)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Spacer()

                            Text("\(item.3) kcal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
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
        date: .now,
        caloriesEaten: 1234,
        dailyGoal: 2500,
        foodItems: [
            ("1", "Apple", .eaten, 95),
            ("2", "Sandwich", .planned, 350),
        ],
        allItems: []
    )
}

#Preview(as: .systemMedium) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        caloriesEaten: 1800,
        dailyGoal: 2500,
        foodItems: [
            ("1", "Apple", .eaten, 95),
            ("2", "Sandwich", .planned, 350),
            ("3", "Salad", .eaten, 120),
            ("4", "Yogurt", .eaten, 150),
        ],
        allItems: []
    )
}

struct LargeWidgetView: View {
    let entry: SimpleEntry

    private var remainingCalories: Int {
        entry.dailyGoal - entry.caloriesEaten
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Nutrition")
                        .font(.headline)
                        .fontWeight(.medium)

                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(entry.caloriesEaten)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("/ \(entry.dailyGoal) kcal")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    if remainingCalories >= 0 {
                        Text("\(remainingCalories) left")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    } else {
                        Text("\(abs(remainingCalories)) over")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }

                    // Progress bar
                    ProgressView(
                        value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                        total: Double(entry.dailyGoal)
                    )
                    .tint(remainingCalories >= 0 ? .green : .red)
                    .frame(width: 100)
                }
            }

            // Food items grid
            if entry.foodItems.isEmpty {
                VStack {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No food items today")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Array(entry.foodItems.prefix(8).enumerated()), id: \.offset) {
                        index, item in
                        HStack {
                            Button(intent: ToggleFoodStatusIntent(foodItemId: item.0)) {
                                Image(systemName: item.2.systemImage)
                                    .font(.body)
                                    .foregroundColor(item.2 == .eaten ? .green : .gray)
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
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct ExtraLargeWidgetView: View {
    let entry: SimpleEntry

    private var remainingCalories: Int {
        entry.dailyGoal - entry.caloriesEaten
    }

    private var eatenItems: [(String, String, FoodItem.FoodStatus, Int)] {
        entry.foodItems.filter { $0.2 == .eaten }
    }

    private var plannedItems: [(String, String, FoodItem.FoodStatus, Int)] {
        entry.foodItems.filter { $0.2 == .planned }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with comprehensive stats
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Nutrition Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(alignment: .bottom, spacing: 6) {
                        Text("\(entry.caloriesEaten)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("/ \(entry.dailyGoal) kcal")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    // Progress bar
                    ProgressView(
                        value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)),
                        total: Double(entry.dailyGoal)
                    )
                    .tint(remainingCalories >= 0 ? .green : .red)
                    .scaleEffect(y: 2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 12) {
                    VStack(alignment: .trailing) {
                        if remainingCalories >= 0 {
                            Text("\(remainingCalories)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("calories left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(abs(remainingCalories))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("calories over")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .trailing) {
                        Text("\(eatenItems.count)/\(entry.foodItems.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("items eaten")
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
        date: .now,
        caloriesEaten: 1234,
        dailyGoal: 2500,
        foodItems: [
            ("1", "Apple", .eaten, 95),
            ("2", "Sandwich", .planned, 350),
        ],
        allItems: []
    )
}

#Preview(as: .systemMedium) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        caloriesEaten: 1800,
        dailyGoal: 2500,
        foodItems: [
            ("1", "Apple", .eaten, 95),
            ("2", "Sandwich", .planned, 350),
            ("3", "Salad", .eaten, 120),
            ("4", "Yogurt", .eaten, 150),
        ],
        allItems: []
    )
}

#Preview(as: .systemLarge) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        caloriesEaten: 1400,
        dailyGoal: 2500,
        foodItems: [
            ("1", "Apple", .eaten, 95),
            ("2", "Sandwich", .planned, 350),
            ("3", "Salad", .eaten, 120),
            ("4", "Yogurt", .eaten, 150),
            ("5", "Chicken Breast", .planned, 200),
            ("6", "Rice", .planned, 150),
            ("7", "Broccoli", .eaten, 30),
            ("8", "Almonds", .planned, 160),
        ],
        allItems: []
    )
}

#Preview(as: .systemExtraLarge) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        caloriesEaten: 1600,
        dailyGoal: 2200,
        foodItems: [
            ("1", "Apple", .eaten, 95),
            ("2", "Sandwich", .eaten, 350),
            ("3", "Salad", .eaten, 120),
            ("4", "Yogurt", .eaten, 150),
            ("5", "Chicken Breast", .planned, 200),
            ("6", "Rice", .planned, 150),
            ("7", "Broccoli", .eaten, 30),
            ("8", "Almonds", .planned, 160),
            ("9", "Banana", .planned, 100),
            ("10", "Greek Yogurt", .planned, 120),
        ],
        allItems: []
    )
}
