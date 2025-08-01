# 🍽️ Nutrition Tracker - Complete Setup Guide

## 📋 Prerequisites
- macOS (required for Xcode)
- Xcode installed from Mac App Store (~15GB)

## 🚀 Step-by-Step Setup

### 1. Create New Xcode Project
1. Open Xcode
2. Choose "Create a new Xcode project"
3. Select **iOS** → **App**
4. Project settings:
   - **Product Name**: `NutritionTracker`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Use Core Data**: `NO` (we're using SwiftData)
   - **Bundle Identifier**: `com.yourname.nutritiontracker` (replace 'yourname')

### 2. Add Widget Extension
1. **File** → **New** → **Target**
2. Select **iOS** → **Widget Extension**
3. Settings:
   - **Product Name**: `NutritionWidget`
   - **Include Configuration Intent**: `NO`
4. Click **Finish**, then **Activate** when prompted

### 3. Configure App Groups
**For Main App:**
1. Select `NutritionTracker` target
2. **Signing & Capabilities** tab
3. **+ Capability** → **App Groups**
4. **+** → Enter: `group.com.yourname.nutritiontracker`
5. Check the checkbox

**For Widget:**
1. Select `NutritionWidget` target
2. **Signing & Capabilities** tab
3. **+ Capability** → **App Groups**
4. Select the same group you created
5. Check the checkbox

### 4. Replace Default Files

**⚠️ IMPORTANT: Update the App Group ID**
Before adding files, you MUST update the App Group ID in two places:

**In `NutritionTrackerApp.swift`:**
```swift
static let appGroupID = "group.com.YOURNAME.nutritiontracker"
```

**In `NutritionWidget.swift`:**
```swift
groupContainer: .identifier("group.com.YOURNAME.nutritiontracker")
```

Replace `YOURNAME` with the same name you used in your Bundle Identifier.

### 5. Add Files to Main App Target

**Delete these default files first:**
- `ContentView.swift` (we'll replace it)

**Add these files to your main app:**

1. **`FoodItem.swift`** - SwiftData model
2. **`NutritionTrackerApp.swift`** - Replace the default app file
3. **`ContentView.swift`** - Main navigation
4. **`AddFoodView.swift`** - Add food screen
5. **`DailyView.swift`** - Daily tracking screen

### 6. Add Files to Widget Target

**Replace the default widget file:**
- Delete `NutritionWidget.swift` from widget target
- Add our **`NutritionWidget.swift`** to widget target

### 7. File Organization in Xcode

Your project structure should look like this:

```
NutritionTracker/
├── NutritionTracker/
│   ├── NutritionTrackerApp.swift
│   ├── ContentView.swift
│   ├── AddFoodView.swift
│   ├── DailyView.swift
│   └── FoodItem.swift
└── NutritionWidget/
    └── NutritionWidget.swift
```

### 8. Build and Test

1. Select **NutritionTracker** scheme (top left)
2. Choose **iPhone 15** simulator
3. Press **Cmd+R** to build and run

## 🧪 Testing the App

### Main App Testing:
1. **Add Food Items**: Tap + button, enter name and calories
2. **Toggle Status**: Tap circle icons to mark items as eaten
3. **View Progress**: See calorie totals and progress bar
4. **Delete Items**: Swipe left on items to delete

### Widget Testing:
1. **Add Widget**: Long press home screen → + → Search "Nutrition"
2. **Test Updates**: Add/update items in app, widget should refresh
3. **Tap Widget**: Should open the main app

## 🐛 Troubleshooting

### Build Errors:
- **"Cannot find 'FoodItem' in scope"**: Make sure `FoodItem.swift` is added to main target
- **Widget not updating**: Check App Group IDs match exactly
- **SwiftData errors**: Ensure iOS deployment target is 17.0+

### Widget Issues:
- **Widget shows placeholder**: Check App Group configuration
- **Data not syncing**: Verify both targets have same App Group ID
- **Widget not appearing**: Make sure Widget Extension target builds successfully

## 🎯 App Features

### ✅ Completed Features:
- Manual food entry with calories
- Daily calorie tracking with 2000 kcal goal
- Toggle between planned/eaten status
- Progress visualization with progress bar
- Home screen widget (small and medium sizes)
- Data persistence with SwiftData
- App Groups for widget-app data sharing

### 🔄 How It Works:
1. **Add food items** with name and calorie count
2. **Mark items as eaten** by tapping the circle icon
3. **Track progress** with visual progress bar
4. **Monitor from home screen** via widget
5. **Data syncs automatically** between app and widget

## 🚀 Next Steps (Future Enhancements):
- Weekly meal planning
- Custom daily calorie goals
- Food categories and macronutrients
- Export data functionality
- Dark mode optimization

---

**🎉 You now have a fully functional nutrition tracking app with widget support!**

The app stores all data locally on the device and doesn't require any internet connection or user accounts.