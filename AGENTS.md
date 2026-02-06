# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview
iOS nutrition tracking app (Swift/SwiftUI) with WidgetKit extension. iOS 17.0+, Xcode 16.4+.

## Critical: Duplicated Model Files
The widget extension has **duplicate model files** that must be kept in sync:
- [`FoodItem.swift`](NutritionTracker/NutritionTracker/NutritionTracker/FoodItem.swift) ↔ [`NutritionWidget/FoodItem.swift`](NutritionTracker/NutritionTracker/NutritionWidget/FoodItem.swift)
- [`CalorieGoal.swift`](NutritionTracker/NutritionTracker/NutritionTracker/CalorieGoal.swift) ↔ [`NutritionWidget/CalorieGoal.swift`](NutritionTracker/NutritionTracker/NutritionWidget/CalorieGoal.swift)
- [`FoodHistory.swift`](NutritionTracker/NutritionTracker/NutritionTracker/FoodHistory.swift) ↔ [`NutritionWidget/FoodHistory.swift`](NutritionTracker/NutritionTracker/NutritionWidget/FoodHistory.swift)

**Any changes to these models must be applied to BOTH locations.**

## App Group Configuration
App Group ID: `group.com.OneFifty.Aoo` - Used for sharing data between main app and widget.
- Configured in [`NutritionTracker.entitlements`](NutritionTracker/NutritionTracker/NutritionTracker/NutritionTracker.entitlements)
- Used by [`FoodHistoryManager.shared`](NutritionTracker/NutritionTracker/NutritionTracker/Shared/FoodHistoryManager.swift) for UserDefaults persistence

## Data Storage Pattern
- **SwiftData**: Used for `FoodItem` and `CalorieGoal` (via App Group container)
- **UserDefaults with App Group**: Used for `FoodHistoryManager` (quick-pick feature) - NOT SwiftData

## Build Commands
```bash
# Open project
open NutritionTracker/NutritionTracker/NutritionTracker.xcodeproj

# Build via CLI
xcodebuild -project NutritionTracker/NutritionTracker/NutritionTracker.xcodeproj -scheme NutritionTracker -sdk iphonesimulator -configuration Debug build

# Run tests
xcodebuild -project NutritionTracker/NutritionTracker/NutritionTracker.xcodeproj -scheme NutritionTracker -sdk iphonesimulator test
```

## Theming
Use [`AppTheme`](NutritionTracker/NutritionTracker/NutritionTracker/Theme.swift) constants for colors, spacing, and typography - not raw values.

---

## 📱 Install on Device (When User Says "install")

### Quick One-Liner
```bash
cd NutritionTracker/NutritionTracker && xcodebuild -project NutritionTracker.xcodeproj -target NutritionTracker -sdk iphoneos -configuration Release build && xcrun devicectl device install app --device $(xcrun xctrace list devices 2>&1 | grep "iPhone" | grep -v Simulator | head -1 | sed 's/.*(\([^)]*\))$/\1/') ./build/Release-iphoneos/NutritionTracker.app
```

### Step-by-Step Commands
```bash
# 1. List connected devices (get device ID)
xcrun xctrace list devices 2>&1 | grep -v Simulator

# 2. Build for device
cd NutritionTracker/NutritionTracker
xcodebuild -project NutritionTracker.xcodeproj -target NutritionTracker -sdk iphoneos -configuration Release build

# 3. Install (replace DEVICE_ID with actual ID from step 1)
xcrun devicectl device install app --device DEVICE_ID ./build/Release-iphoneos/NutritionTracker.app

# 4. Launch app
xcrun devicectl device process launch --device DEVICE_ID TomerCode.NutritionTracker
```

### Common Device IDs (Tomer's devices)
- iPhone (26.2.1): `00008140-000E35822182801C`
- tomer's iPhone (2) (26.2): `00008140-001A31881E29801C`

### Troubleshooting
- **Device locked**: Unlock iPhone first
- **Build fails**: Run `xcodebuild -list` to check available targets
- **Provisioning error**: Open in Xcode → Signing & Capabilities → Select team

---

## Project Structure (Non-Obvious)
- Xcode project is nested: `NutritionTracker/NutritionTracker/NutritionTracker.xcodeproj`
- Widget code is in `NutritionWidget/` folder, but target is `NutritionWidgetExtension`

## Architecture Notes (Non-Obvious)
- Main navigation: `ContentView` uses tab-based flow (`DailyView`, `WeeklyPlannerView`, `SettingsView`)
- Both `DayView` and `OptimizedDayView` exist (optimization in progress)
- Both `SwipeableDaysView` and `OptimizedSwipeableDaysView` exist

## Data Systems (Intentional Split)
1. **SwiftData**: `FoodItem`, `CalorieGoal` (App Group container)
2. **UserDefaults**: `FoodHistoryManager` for quick-pick history (uses `FoodHistoryItem`)

Legacy `FoodHistory.swift` (SwiftData) is kept only for migration; current usage is `FoodHistoryItem` (Codable).

## Widget Debugging
- Widget errors are silent; check Xcode console with `NutritionWidgetExtension` scheme selected
- Timeline updates every 15 minutes minimum; use `WidgetCenter.shared.reloadAllTimelines()` to force refresh

## Common Silent Failures
- SwiftData predicate errors fail silently with empty arrays
- Missing App Group entitlement causes nil container (check both `.entitlements` files)
- Widget runs in a separate process; data must flow via the App Group container

## Logging
- `FoodHistoryManager` uses emoji-prefixed debug logs (🍎, 📦, ✅, ❌)
- `#DEBUG` sample data helper: `FoodHistoryManager.shared.addSampleData()`
