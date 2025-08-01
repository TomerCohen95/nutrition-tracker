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
    @State private var showingAddFood = false
    
    var body: some View {
        NavigationView {
            DailyView()
                .navigationTitle("Nutrition Tracker")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddFood = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddFood) {
                    AddFoodView()
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FoodItem.self, inMemory: true)
}