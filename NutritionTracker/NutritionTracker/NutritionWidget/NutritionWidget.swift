//
//  NutritionWidget.swift
//  NutritionWidget
//
//  Home screen widget (Deliverable 3)
//

import WidgetKit
import SwiftUI
import SwiftData

struct NutritionWidget: Widget {
    let kind: String = "NutritionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NutritionWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nutrition Tracker")
        .description("See your daily calorie progress and food items.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            caloriesEaten: 1234,
            dailyGoal: 2000,
            foodItems: [
                ("Apple", .eaten),
                ("Sandwich", .planned),
                ("Salad", .eaten)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            caloriesEaten: 1234,
            dailyGoal: 2000,
            foodItems: [
                ("Apple", .eaten),
                ("Sandwich", .planned),
                ("Salad", .eaten)
            ]
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = fetchCurrentData(for: currentDate)
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func fetchCurrentData(for date: Date) -> SimpleEntry {
        // Create model container with App Group
        let schema = Schema([FoodItem.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
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
            let caloriesEaten = todaysItems
                .filter { $0.status == .eaten }
                .reduce(0) { $0 + $1.calories }
            
            // Prepare food items for display (limit to 4 for widget)
            let displayItems = Array(todaysItems.prefix(4)).map { item in
                (item.name, item.status)
            }
            
            return SimpleEntry(
                date: date,
                caloriesEaten: caloriesEaten,
                dailyGoal: 2000,
                foodItems: displayItems
            )
            
        } catch {
            print("Widget error fetching data: \(error)")
            // Return empty state on error
            return SimpleEntry(
                date: date,
                caloriesEaten: 0,
                dailyGoal: 2000,
                foodItems: []
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let caloriesEaten: Int
    let dailyGoal: Int
    let foodItems: [(String, FoodItem.FoodStatus)]
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
            ProgressView(value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)), 
                        total: Double(entry.dailyGoal))
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
            ProgressView(value: min(Double(entry.caloriesEaten), Double(entry.dailyGoal)), 
                        total: Double(entry.dailyGoal))
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
                            Image(systemName: item.1.systemImage)
                                .font(.caption)
                                .foregroundColor(item.1 == .eaten ? .green : .gray)
                            
                            Text(item.0)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
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
        dailyGoal: 2000,
        foodItems: [
            ("Apple", .eaten),
            ("Sandwich", .planned)
        ]
    )
}

#Preview(as: .systemMedium) {
    NutritionWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        caloriesEaten: 1800,
        dailyGoal: 2000,
        foodItems: [
            ("Apple", .eaten),
            ("Sandwich", .planned),
            ("Salad", .eaten),
            ("Yogurt", .eaten)
        ]
    )
}