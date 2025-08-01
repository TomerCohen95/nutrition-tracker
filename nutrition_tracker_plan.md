# 🍽️ Nutrition Tracker iOS App - Development Plan

## Overview
A minimalist nutrition tracking app built with SwiftUI and WidgetKit, using SwiftData for local storage. No external APIs or databases - all food items are entered manually.

## Development Environment Setup

### What You Need to Install:
1. **Xcode** (from Mac App Store - ~15GB)
   - Required for iOS development and iOS Simulator
   - Includes all necessary SDKs and tools
   - **Free to download and use**

### Testing Your App:
- **iOS Simulator** (included with Xcode) - **Completely Free**
  - Simulates iPhone/iPad on your Mac
  - Test all app features including widgets
  - No physical device needed for development

## Technical Architecture

### Data Model (SwiftData)
```swift
@Model
class FoodItem {
    var id: UUID
    var name: String
    var calories: Int
    var date: Date
    var status: FoodStatus
    var createdAt: Date
    
    enum FoodStatus: String, CaseIterable, Codable {
        case planned = "planned"
        case eaten = "eaten"
    }
}
```

### Project Structure
```
NutritionTracker/
├── NutritionTracker/           # Main app target
│   ├── Models/
│   │   ├── FoodItem.swift
│   │   └── DataManager.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── AddFoodView.swift
│   │   └── DailyView.swift
│   └── NutritionTrackerApp.swift
├── NutritionWidget/            # Widget extension
│   ├── NutritionWidget.swift
│   ├── NutritionWidgetEntry.swift
│   └── TimelineProvider.swift
└── Shared/
    └── AppGroup.swift
```

## Deliverable Breakdown

### Deliverable 1: Add Food Item Screen
**Technical Requirements:**
- SwiftUI Form with TextField and NumberField
- SwiftData persistence with date tagging
- Input validation (non-empty name, positive calories)
- Success feedback after saving

**User Experience:**
- Simple form: "Food Name" + "Calories"
- "Add Item" button
- Auto-dismiss on success
- Items default to "planned" status

### Deliverable 2: Daily View Screen
**Technical Requirements:**
- SwiftData query filtered by today's date
- Computed properties for calorie totals
- Toggle state management for eaten/planned
- Real-time UI updates

**User Experience:**
- List of today's food items
- Toggle button: "Planned" ↔ "Eaten"
- Top summary: "1,234 / 2,000 calories"
- "Remaining: 766 calories" or "Over by: 234 calories"

### Deliverable 3: Home Screen Widget
**Technical Requirements:**
- WidgetKit with TimelineProvider
- App Groups for data sharing
- SwiftData queries in widget context
- Proper timeline refresh intervals

**Widget Content:**
- Today's date
- List of food items (3-4 max for space)
- Total calories: "1,234 / 2,000"
- Tap to open main app

## App Groups Configuration
```swift
// App Group ID
let appGroupID = "group.com.yourname.nutritiontracker"

// Shared container URL
let sharedContainerURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
```

## Key SwiftData Features Used
- `@Model` for data persistence
- `@Query` for reactive data fetching
- ModelContext for CRUD operations
- Date-based filtering for daily views

## Development Workflow

### Phase 1: Foundation (Steps 1-5)
- Install Xcode and create project
- Set up SwiftData models and storage
- Configure App Groups for widget sharing

### Phase 2: Core App (Steps 6-9)
- Build main app screens
- Implement food adding and status toggling
- Test in iOS Simulator

### Phase 3: Widget (Steps 10-12)
- Create WidgetKit extension
- Connect to shared data
- Test widget updates

### Phase 4: Polish (Step 13)
- Final testing and refinements

## Testing Strategy
- Use iOS Simulator for all testing (free)
- Test widget on home screen simulation
- Verify data persistence across app launches
- Test edge cases (no items, high calorie counts)

## Performance Considerations
- SwiftData queries are optimized for date ranges
- Widget updates are throttled by iOS
- Minimal memory footprint with local-only data

---

This plan keeps the MVP focused and extensible. Each deliverable builds on the previous one, ensuring a working app at each stage.