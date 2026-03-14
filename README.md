# 🍽️ Nutrition Tracker iOS App

A minimalist nutrition tracking app built with **SwiftUI** and **WidgetKit**, featuring local-only data storage with **SwiftData**.

## ✨ Features

### 📱 Main App
- **Manual Food Entry** - Add food items with name and calorie count
- **Daily Tracking** - View today's meals with planned/eaten status
- **Calorie Progress** - Visual progress bar showing calories consumed vs. daily goal (2000 kcal)
- **Simple Toggle** - Mark items as eaten by tapping the circle icon
- **Swipe to Delete** - Remove items with left swipe gesture

### 🏠 Home Screen Widget
- **Small Widget** - Shows calorie progress and remaining/over amount
- **Medium Widget** - Displays progress plus list of today's food items
- **Live Updates** - Widget refreshes automatically when app data changes
- **Tap to Open** - Tap widget to launch the main app

### 🔒 Privacy & Storage
- **100% Local** - No internet connection required
- **No Accounts** - No login or user accounts needed
- **Device Only** - All data stays on your device
- **App Groups** - Secure data sharing between app and widget

## 🛠️ Technical Stack

- **SwiftUI** - Modern iOS user interface framework
- **SwiftData** - Apple's latest data persistence framework
- **WidgetKit** - Native iOS home screen widgets
- **App Groups** - Secure container for app-widget data sharing
- **iOS 17.0+** - Minimum deployment target

## 📋 Installation & Setup

### Prerequisites
- **macOS** (required for Xcode)
- **Xcode** from Mac App Store (~15GB, free)
- **Apple Developer Account** (free or paid) - required for device installation

---

## 📱 Install on Your iPhone (Quick Commands)

### Step 1: List Connected Devices
```bash
xcrun xctrace list devices 2>&1 | grep -v Simulator
```

### Step 2: Build for Device
```bash
cd NutritionTracker/NutritionTracker
xcodebuild -project NutritionTracker.xcodeproj \
  -target NutritionTracker \
  -sdk iphoneos \
  -configuration Release \
  build
```

### Step 3: Install on Device
Replace `YOUR_DEVICE_ID` with your device ID from Step 1:
```bash
xcrun devicectl device install app \
  --device YOUR_DEVICE_ID \
  ./build/Release-iphoneos/NutritionTracker.app
```

### Step 4: Launch App
```bash
xcrun devicectl device process launch \
  --device YOUR_DEVICE_ID \
  TomerCode.NutritionTracker
```

### 🔧 Troubleshooting

| Error | Solution |
|-------|----------|
| "Device is locked" | Unlock your iPhone and try again |
| "Provisioning profile" error | Open project in Xcode, go to Signing & Capabilities, select your team |
| "Device not found" | Reconnect USB cable, trust computer on iPhone |

---

## 💻 Install on Simulator (Alternative)

### Build and Run
```bash
cd NutritionTracker/NutritionTracker

# Build for simulator
xcodebuild -project NutritionTracker.xcodeproj \
  -target NutritionTracker \
  -sdk iphonesimulator \
  -configuration Debug \
  build

# Install
xcrun simctl install "iPhone 16 Pro" \
  ./build/Debug-iphonesimulator/NutritionTracker.app

# Launch
xcrun simctl launch "iPhone 16 Pro" TomerCode.NutritionTracker

# Open Simulator app
open -a Simulator
```

---

## 📖 Detailed Setup Guide

For step-by-step instructions with screenshots:
1. [`SETUP_GUIDE.md`](SETUP_GUIDE.md) - Complete Xcode setup
2. [`INSTALL_ON_REAL_IPHONE.md`](INSTALL_ON_REAL_IPHONE.md) - Device-specific guide

## 🎯 MVP Deliverables Completed

### ✅ Deliverable 1: Add Food Item Screen
- Simple form with food name and calories
- Input validation and error handling
- Local storage with SwiftData
- Success feedback and auto-dismiss

### ✅ Deliverable 2: Daily View Screen  
- List of today's food items sorted by creation time
- Toggle button to mark items as planned/eaten
- Calorie summary with progress visualization
- Empty state for when no items exist

### ✅ Deliverable 3: Home Screen Widget
- Timeline provider with automatic updates
- Small and medium widget sizes supported
- Real-time calorie progress display
- Food item list in medium widget

## 🧪 Testing

### Using iOS Simulator (Free)
- **Main App**: Add items, toggle status, view progress
- **Widget**: Add to simulated home screen, test updates
- **Data Sync**: Verify changes appear in both app and widget

### Test Scenarios
1. Add multiple food items
2. Mark some as eaten, leave others planned
3. Check calorie calculations are correct
4. Verify widget updates automatically
5. Test widget tap opens main app

## 🏗️ Architecture

### Data Model
```swift
@Model
class FoodItem {
    var name: String
    var calories: Int
    var date: Date
    var status: FoodStatus // .planned or .eaten
}
```

### Key Components
- **ContentView** - Main navigation controller
- **AddFoodView** - Food entry form
- **DailyView** - Today's items with progress
- **NutritionWidget** - Home screen widget with timeline

### Data Flow
1. User adds food in `AddFoodView`
2. Item saved to SwiftData with App Group
3. `DailyView` displays items with real-time updates
4. Widget reads from shared container and displays summary
5. Timeline provider refreshes widget every 15 minutes

## 🚀 Future Enhancements

- **Weekly Planning** - Add meals for future dates
- **Custom Goals** - User-configurable daily calorie targets
- **Macronutrients** - Track protein, carbs, and fat
- **Categories** - Organize foods by meal type
- **Export Data** - Share progress data
- **Dark Mode** - Enhanced dark mode support

## 📱 Screenshots

*Screenshots will be available after running in iOS Simulator*

## 🤝 Development Principles

- **Keep It Simple** - No over-engineering, clean MVP approach
- **Extensible Design** - Easy to add features later
- **Performance First** - Optimized queries and efficient widgets
- **Privacy Focused** - Local-only, no tracking or analytics

---

**Built with ❤️ using SwiftUI and SwiftData**

*This app demonstrates modern iOS development practices with a focus on simplicity, performance, and user privacy.*