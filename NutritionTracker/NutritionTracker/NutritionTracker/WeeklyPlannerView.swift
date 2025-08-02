//
//  WeeklyPlannerView.swift
//  NutritionTracker
//
//  Enhanced monthly meal planning with multi-select day copying functionality
//

import SwiftData
import SwiftUI
import WidgetKit

struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFoodItems: [FoodItem]
    @Query(sort: \CalorieGoal.effectiveDate, order: .reverse) var calorieGoals: [CalorieGoal]

    @State private var selectedDate = Date()
    @State private var showingAddFood = false
    @State private var showingCopyDayAlert = false
    @State private var showingCopyConfirmation = false
    @State private var viewMode: ViewMode = .week
    @State private var currentMonth = Date()
    @State private var showingEditFood = false
    @State private var selectedItemToEdit: FoodItem?
    @State private var showingCopyTodays = false
    @State private var selectedItemToCopy: FoodItem?

    enum ViewMode: String, CaseIterable {
        case week = "Week"
        case month = "Month"

        var systemImage: String {
            switch self {
            case .week: return "calendar.day.timeline.trailing"
            case .month: return "calendar"
            }
        }
    }

    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek =
            calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        let startOfMonth = monthInterval.start

        // Get first day of week that contains the first day of month
        let startOfWeekForMonth =
            calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth

        var dates: [Date] = []
        var currentDate = startOfWeekForMonth

        // Generate 6 weeks worth of dates (42 days) to fill calendar grid
        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    private var selectedDayItems: [FoodItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return allFoodItems.filter { item in
            item.date >= startOfDay && item.date < endOfDay
        }.sorted { $0.createdAt < $1.createdAt }
    }

    private var caloriesEaten: Int {
        selectedDayItems
            .filter { $0.status == .eaten }
            .reduce(0) { $0 + $1.calories }
    }

    private var dailyGoal: Int {
        CalorieGoal.currentGoal(for: selectedDate, from: calorieGoals)
    }

    private var remainingCalories: Int {
        dailyGoal - caloriesEaten
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Picker
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, AppTheme.paddingM)
                .padding(.top, AppTheme.paddingXS)

                // Calendar Navigation
                if viewMode == .month {
                    monthNavigationHeader
                }

                // Calendar View
                if viewMode == .week {
                    weekCalendarView
                } else {
                    monthCalendarView
                }

                Divider()

                // Selected Day Content - Make this scrollable
                ScrollView {
                    selectedDayContentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddFood) {
            AddFoodView(targetDate: selectedDate)
        }
        .alert("Copy Day", isPresented: $showingCopyDayAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Choose Days") {
                showingCopyConfirmation = true
            }
        } message: {
            Text("Copy all meals from \(dayName(for: selectedDate)) to other days?")
        }
        .sheet(isPresented: $showingCopyConfirmation) {
            EnhancedCopyDaySheet(
                sourceDate: selectedDate,
                onCopy: copyDayToMultipleDates
            )
        }
        .sheet(isPresented: $showingEditFood) {
            if let item = selectedItemToEdit {
                EditFoodView(foodItem: item)
            }
        }
        .sheet(isPresented: $showingCopyTodays) {
            if let item = selectedItemToCopy {
                CopyToDaysView(foodItem: item)
            }
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button(action: {
                currentMonth =
                    Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)
                    ?? currentMonth
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryGreen)
            }

            Spacer()

            Text(monthTitle)
                .font(AppTheme.headlineFont)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Button(action: {
                currentMonth =
                    Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)
                    ?? currentMonth
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryGreen)
            }
        }
        .padding(.horizontal, AppTheme.paddingM)
        .padding(.bottom, AppTheme.paddingS)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var weekCalendarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.paddingS) {
                ForEach(currentWeekDates, id: \.self) { date in
                    WeekDayButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasPlannedMeals: hasPlannedMeals(for: date)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, AppTheme.paddingM)
        }
        .padding(.vertical, AppTheme.paddingXS)
    }

    private var monthCalendarView: some View {
        VStack(spacing: AppTheme.paddingXS) {
            // Week day headers
            HStack {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(AppTheme.captionFont)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.paddingM)

            // Calendar grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: AppTheme.paddingXS
            ) {
                ForEach(monthDates, id: \.self) { date in
                    MonthDayButton(
                        date: date,
                        currentMonth: currentMonth,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasPlannedMeals: hasPlannedMeals(for: date)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, AppTheme.paddingM)
        }
        .padding(.vertical, AppTheme.paddingXS)
    }

    private var selectedDayContentView: some View {
        VStack(spacing: AppTheme.paddingM) {
            // Header with date and stats
            VStack(spacing: AppTheme.paddingM) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.paddingXS) {
                        Text(dateTitle(for: selectedDate))
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(alignment: .bottom, spacing: AppTheme.paddingXS) {
                            Text("\(caloriesEaten)")
                                .font(AppTheme.titleFont)
                                .foregroundColor(AppTheme.primaryGreen)

                            Text("/ \(dailyGoal) cal")
                                .font(AppTheme.bodyFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppTheme.paddingXS) {
                        HStack(spacing: AppTheme.paddingS) {
                            Button(action: { showingAddFood = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Food")
                                }
                                .font(AppTheme.captionFont)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppTheme.paddingM)
                                .padding(.vertical, AppTheme.paddingS)
                                .background(AppTheme.primaryGreen)
                                .cornerRadius(20)
                                .fixedSize(horizontal: true, vertical: false)
                            }

                            if !selectedDayItems.isEmpty {
                                Button(action: { showingCopyDayAlert = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy Day")
                                    }
                                    .font(AppTheme.captionFont)
                                    .foregroundColor(AppTheme.primaryGreen)
                                    .padding(.horizontal, AppTheme.paddingM)
                                    .padding(.vertical, AppTheme.paddingS)
                                    .background(AppTheme.lightGreen)
                                    .cornerRadius(20)
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                        }

                        VStack(alignment: .trailing, spacing: AppTheme.paddingXS) {
                            Text("Remaining")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(remainingCalories)")
                                .font(AppTheme.headlineFont)
                                .foregroundColor(
                                    remainingCalories >= 0
                                        ? AppTheme.primaryGreen : AppTheme.accentOrange)
                        }
                    }
                }

                ProgressView(value: Double(caloriesEaten), total: Double(dailyGoal))
                    .tint(remainingCalories >= 0 ? AppTheme.primaryGreen : AppTheme.accentOrange)
            }
            .padding(AppTheme.paddingL)
            .cardStyle(backgroundColor: AppTheme.lightGreen)

            // Food items list
            if selectedDayItems.isEmpty {
                VStack(spacing: AppTheme.paddingM) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.textTertiary)

                    Text("No meals planned")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Tap 'Add Food' to plan meals for \(dayName(for: selectedDate))")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.paddingXL)
            } else {
                LazyVStack(spacing: AppTheme.paddingS) {
                    ForEach(selectedDayItems, id: \.id) { item in
                        WeeklyFoodItemRow(
                            item: item,
                            selectedDate: selectedDate,
                            onToggle: { toggleItemStatus(item) },
                            onDelete: { deleteItem(item) },
                            onEdit: { editItem(item) },
                            onCopy: { copyItem(item) }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)
            }
        }
        .padding(.vertical, AppTheme.paddingS)
        .background(AppTheme.secondaryBackground)
    }

    private func hasPlannedMeals(for date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return allFoodItems.contains { item in
            item.date >= startOfDay && item.date < endOfDay
        }
    }

    private func dateTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today's Progress"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow's Plan"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday's Meals"
        } else {
            let formatter = DateFormatter()
            if calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending {
                formatter.dateFormat = "EEEE's Plan"
            } else {
                formatter.dateFormat = "EEEE's Meals"
            }
            return formatter.string(from: date)
        }
    }

    private func dayName(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }

    private func toggleItemStatus(_ item: FoodItem) {
        // Only allow toggling to "eaten" for today and past days
        let calendar = Calendar.current
        if calendar.compare(selectedDate, to: Date(), toGranularity: .day) != .orderedDescending {
            item.toggleStatus()

            do {
                try modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Error updating item status: \(error)")
            }
        }
    }

    private func deleteItem(_ item: FoodItem) {
        modelContext.delete(item)

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error deleting item: \(error)")
        }
    }

    private func editItem(_ item: FoodItem) {
        selectedItemToEdit = item
        showingEditFood = true
    }

    private func copyItem(_ item: FoodItem) {
        selectedItemToCopy = item
        showingCopyTodays = true
    }

    private func copyDayToMultipleDates(_ destinationDates: [Date]) {
        // Copy all items from selected date to multiple destination dates
        for destinationDate in destinationDates {
            for item in selectedDayItems {
                let copiedItem = FoodItem(
                    name: item.name,
                    calories: item.calories,
                    date: Calendar.current.startOfDay(for: destinationDate)
                )

                modelContext.insert(copiedItem)
            }
        }

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error copying day: \(error)")
        }
    }
}

struct WeekDayButton: View {
    let date: Date
    let isSelected: Bool
    let hasPlannedMeals: Bool
    let action: () -> Void

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }

    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.caption)
                    .fontWeight(.medium)

                Text(dayNumberFormatter.string(from: date))
                    .font(.title3)
                    .fontWeight(.semibold)

                if hasPlannedMeals {
                    Circle()
                        .fill(isSelected ? .white : AppTheme.primaryGreen)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 50, height: 70)
            .background(isSelected ? AppTheme.primaryGreen : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.primaryGreen.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MonthDayButton: View {
    let date: Date
    let currentMonth: Date
    let isSelected: Bool
    let hasPlannedMeals: Bool
    let action: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isInCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)

                if hasPlannedMeals {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if !isInCurrentMonth {
            return AppTheme.textTertiary
        } else if isToday {
            return AppTheme.primaryGreen
        } else {
            return AppTheme.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return AppTheme.primaryGreen
        } else if isToday {
            return AppTheme.lightGreen
        } else {
            return Color.clear
        }
    }

    private var dotColor: Color {
        if isSelected {
            return .white
        } else {
            return AppTheme.primaryGreen
        }
    }

    private var borderColor: Color {
        if isToday && !isSelected {
            return AppTheme.primaryGreen
        } else {
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        isToday && !isSelected ? 1 : 0
    }
}

struct WeeklyFoodItemRow: View {
    let item: FoodItem
    let selectedDate: Date
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void

    private var canToggleStatus: Bool {
        // Can only toggle to "eaten" for today and past days
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day)
            != .orderedDescending
    }

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.status.systemImage)
                    .font(.title2)
                    .foregroundColor(
                        item.status == .eaten ? AppTheme.primaryGreen : AppTheme.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canToggleStatus)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(AppTheme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)

                Text(canToggleStatus ? item.status.displayName : "Planned")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.calories)")
                    .font(AppTheme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text("cal")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundColor(AppTheme.accentOrange)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.paddingM)
        .cardStyle()
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                onCopy()
            } label: {
                Label("Copy to Days", systemImage: "calendar.badge.plus")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct EnhancedCopyDaySheet: View {
    let sourceDate: Date
    let onCopy: ([Date]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDates: Set<Date> = []
    @State private var currentMonth = Date()

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)!
        let startOfMonth = monthInterval.start

        // Get first day of week that contains the first day of month
        let startOfWeekForMonth =
            calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth

        var dates: [Date] = []
        var currentDate = startOfWeekForMonth

        // Generate 6 weeks worth of dates (42 days) to fill calendar grid
        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var sourceDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: sourceDate)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.paddingM) {
                // Source info
                Text("Copy meals from \(sourceDateString) to:")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, AppTheme.paddingM)

                // Month navigation
                HStack {
                    Button(action: {
                        currentMonth =
                            Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)
                            ?? currentMonth
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryGreen)
                    }

                    Spacer()

                    Text(monthTitle)
                        .font(AppTheme.headlineFont)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: {
                        currentMonth =
                            Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)
                            ?? currentMonth
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)

                // Week day headers
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(AppTheme.captionFont)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)

                // Calendar grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                    spacing: AppTheme.paddingXS
                ) {
                    ForEach(monthDates, id: \.self) { date in
                        CopyDayButton(
                            date: date,
                            currentMonth: currentMonth,
                            sourceDate: sourceDate,
                            isSelected: selectedDates.contains(date),
                            onToggle: {
                                if selectedDates.contains(date) {
                                    selectedDates.remove(date)
                                } else {
                                    selectedDates.insert(date)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.paddingM)

                Spacer()

                // Selection summary
                if !selectedDates.isEmpty {
                    Text(
                        "\(selectedDates.count) day\(selectedDates.count == 1 ? "" : "s") selected"
                    )
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryGreen)
                    .padding(.horizontal, AppTheme.paddingM)
                }
            }
            .navigationTitle("Copy to Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy") {
                        onCopy(Array(selectedDates))
                        dismiss()
                    }
                    .disabled(selectedDates.isEmpty)
                }
            }
        }
    }
}

struct CopyDayButton: View {
    let date: Date
    let currentMonth: Date
    let sourceDate: Date
    let isSelected: Bool
    let onToggle: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isInCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private var isSourceDate: Bool {
        Calendar.current.isDate(date, inSameDayAs: sourceDate)
    }

    private var isPastDate: Bool {
        Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }

    var body: some View {
        Button(action: isSourceDate ? {} : onToggle) {
            Text(dayNumber)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .overlay(
                    isSelected
                        ? Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.white) : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isSourceDate)
    }

    private var textColor: Color {
        if isSourceDate {
            return AppTheme.textTertiary
        } else if isSelected {
            return .white
        } else if !isInCurrentMonth {
            return AppTheme.textTertiary
        } else {
            return AppTheme.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSourceDate {
            return AppTheme.textTertiary.opacity(0.2)
        } else if isSelected {
            return AppTheme.primaryGreen
        } else {
            return Color.clear
        }
    }

    private var borderColor: Color {
        if isSelected {
            return AppTheme.primaryGreen
        } else {
            return AppTheme.textTertiary.opacity(0.3)
        }
    }

    private var borderWidth: CGFloat {
        1
    }
}

#Preview {
    WeeklyPlannerView()
        .modelContainer(for: [FoodItem.self, FoodHistory.self, CalorieGoal.self], inMemory: true)
}
