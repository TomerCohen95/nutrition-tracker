//
//  ContentView.swift
//  NutritionTracker
//
//  Main navigation view
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Swipeable Days View
            NavigationView {
                OptimizedSwipeableDaysView()
            }
            .tabItem {
                Image(systemName: "fork.knife.circle.fill")
                Text("Days")
            }
            .tag(0)
            
            // Weekly Planner
            NavigationView {
                WeeklyPlannerView()
                    .navigationTitle("Weekly Planner")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "calendar.badge.plus")
                Text("Plan")
            }
            .tag(1)
            
        }
        .accentColor(AppTheme.primaryGreen)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, CalorieGoal.self], inMemory: true)
}