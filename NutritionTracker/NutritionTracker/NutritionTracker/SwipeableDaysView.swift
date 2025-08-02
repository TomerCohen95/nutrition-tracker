//
//  SwipeableDaysView.swift
//  NutritionTracker
//
//  A swipeable container for navigating between different days
//

import SwiftUI

struct SwipeableDaysView: View {
    @State private var currentDateIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showingSettings = false
    
    // Generate array of dates (yesterday, today, tomorrow, and a few more days)
    private let dates: [Date] = {
        let calendar = Calendar.current
        let today = Date()
        var datesArray: [Date] = []
        
        // Add past 3 days, today, and next 10 days
        for i in -3...10 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                datesArray.append(date)
            }
        }
        return datesArray
    }()
    
    // Start with today (index 3 in our array)
    init() {
        _currentDateIndex = State(initialValue: 3)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    DayView(date: date)
                        .frame(width: geometry.size.width)
                }
            }
            .offset(x: -CGFloat(currentDateIndex) * geometry.size.width + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold: CGFloat = geometry.size.width * 0.25
                        
                        withAnimation(.easeOut(duration: 0.3)) {
                            if value.translation.width > threshold && currentDateIndex > 0 {
                                // Swipe right - go to previous day
                                currentDateIndex -= 1
                            } else if value.translation.width < -threshold && currentDateIndex < dates.count - 1 {
                                // Swipe left - go to next day
                                currentDateIndex += 1
                            }
                            dragOffset = 0
                        }
                    }
            )
            .animation(.easeOut(duration: isDragging ? 0 : 0.3), value: currentDateIndex)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // Settings button (only show when on today)
                    if currentDateIndex == 3 { // Today is at index 3
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                    
                    // Calendar button to jump back to today
                    Button {
                        withAnimation(.easeOut(duration: 0.3)) {
                            currentDateIndex = 3 // Jump back to today
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .opacity(currentDateIndex == 3 ? 0.3 : 1.0) // Dim when already on today
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var navigationTitle: String {
        let currentDate = dates[currentDateIndex]
        
        if Calendar.current.isDateInToday(currentDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(currentDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(currentDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: currentDate)
        }
    }
}

#Preview {
    NavigationView {
        SwipeableDaysView()
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}