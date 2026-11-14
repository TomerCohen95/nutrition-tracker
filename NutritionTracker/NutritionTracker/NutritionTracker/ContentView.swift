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
    @State private var voiceMeal: VoiceMealRequest?

    private struct VoiceMealRequest: Identifiable {
        let id = UUID()
        let date: Date
        var startsAutomatically = false
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Swipeable Days View
            NavigationView {
                OptimizedSwipeableDaysView { date in
                    voiceMeal = VoiceMealRequest(date: date)
                }
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
        .sheet(item: $voiceMeal) { request in
            VoiceMealView(date: request.date, startsAutomatically: request.startsAutomatically)
        }
        .onOpenURL { url in
            guard url.scheme == "markeat-journal", url.host == "record-meal", voiceMeal == nil else { return }
            selectedTab = 0
            voiceMeal = VoiceMealRequest(date: Date(), startsAutomatically: true)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodItem.self, CalorieGoal.self], inMemory: true)
}