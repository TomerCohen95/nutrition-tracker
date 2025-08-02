//
//  OptimizedSwipeableDaysView.swift
//  NutritionTracker
//
//  High-performance swipeable day view with lazy loading and view recycling
//

import SwiftUI

struct OptimizedSwipeableDaysView: View {
    @State private var currentDateIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showingSettings = false
    
    // Performance optimization: Only keep 3 views in memory
    @State private var visibleViewIndices: Set<Int> = []
    
    // Generate date range (yesterday, today, tomorrow, and more days)
    private let dateRange: DateRange
    
    // Performance: Use struct for better memory management
    private struct DateRange {
        let dates: [Date]
        let todayIndex: Int
        
        init() {
            let calendar = Calendar.current
            let today = Date()
            
            var datesArray: [Date] = []
            // Add past 3 days, today, and next 10 days
            for i in -3...10 {
                if let date = calendar.date(byAdding: .day, value: i, to: today) {
                    datesArray.append(date)
                }
            }
            
            self.dates = datesArray
            self.todayIndex = 3 // Today is at index 3
        }
    }
    
    init() {
        self.dateRange = DateRange()
        _currentDateIndex = State(initialValue: dateRange.todayIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Only render visible views (current + adjacent)
                ForEach(visibleIndices, id: \.self) { index in
                    OptimizedDayView(date: dateRange.dates[index])
                        .frame(width: geometry.size.width)
                        .offset(x: CGFloat(index - currentDateIndex) * geometry.size.width + dragOffset)
                        .opacity(shouldShowView(index: index) ? 1 : 0)
                }
            }
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            updateVisibleViews(geometry: geometry)
                        }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = geometry.size.width * 0.25
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        
                        // Determine swipe direction with velocity consideration
                        let shouldSwipeLeft = value.translation.width < -threshold || velocity < -300
                        let shouldSwipeRight = value.translation.width > threshold || velocity > 300
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if shouldSwipeRight && currentDateIndex > 0 {
                                // Swipe right - go to previous day
                                currentDateIndex -= 1
                            } else if shouldSwipeLeft && currentDateIndex < dateRange.dates.count - 1 {
                                // Swipe left - go to next day
                                currentDateIndex += 1
                            }
                            
                            dragOffset = 0
                            isDragging = false
                        }
                        
                        // Update visible views after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            updateVisibleViews(geometry: geometry)
                        }
                    }
            )
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // Settings button (only show when on today)
                    if currentDateIndex == dateRange.todayIndex {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                    
                    // Calendar button to jump back to today
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentDateIndex = dateRange.todayIndex
                            dragOffset = 0
                        }
                        
                        // Update visible views after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            updateVisibleViews(geometry: nil)
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .opacity(currentDateIndex == dateRange.todayIndex ? 0.3 : 1.0)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            updateVisibleViews(geometry: nil)
        }
    }
    
    // MARK: - Performance Optimizations
    
    /// Updates which views should be kept in memory (current + adjacent)
    private func updateVisibleViews(geometry: GeometryProxy?) {
        let newVisibleIndices = Set([
            max(0, currentDateIndex - 1),                    // Previous day
            currentDateIndex,                                // Current day
            min(dateRange.dates.count - 1, currentDateIndex + 1)  // Next day
        ])
        
        // Only update if indices actually changed to prevent unnecessary redraws
        if visibleViewIndices != newVisibleIndices {
            visibleViewIndices = newVisibleIndices
        }
    }
    
    /// Determines if a view should be visible based on current state
    private func shouldShowView(index: Int) -> Bool {
        return visibleViewIndices.contains(index)
    }
    
    /// Returns the visible indices for ForEach
    private var visibleIndices: [Int] {
        return Array(visibleViewIndices).sorted()
    }
    
    // MARK: - UI Helpers
    
    private var navigationTitle: String {
        let currentDate = dateRange.dates[currentDateIndex]
        
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

// MARK: - Performance Extensions

extension OptimizedSwipeableDaysView {
    /// Pre-calculate expensive operations for better performance
    private func precomputeViewPositions(geometry: GeometryProxy) -> [Int: CGFloat] {
        var positions: [Int: CGFloat] = [:]
        
        for index in visibleIndices {
            positions[index] = CGFloat(index - currentDateIndex) * geometry.size.width + dragOffset
        }
        
        return positions
    }
}

#Preview {
    NavigationView {
        OptimizedSwipeableDaysView()
    }
    .modelContainer(for: FoodItem.self, inMemory: true)
}