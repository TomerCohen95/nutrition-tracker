# 📱 iOS Simulator Testing Guide

## Quick Start - Get Your App Running in 10 Minutes

### Step 1: Create the Xcode Project (5 minutes)

1. **Open Xcode** (should already be open)
2. **Click "Create a new Xcode project"**
3. **Select iOS → App**
4. **Fill in project details:**
   - Product Name: `NutritionTracker`
   - Bundle Identifier: `com.yourname.nutritiontracker` (replace yourname)
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: `UNCHECKED` ❌
5. **Save in**: `/Users/tomercohen/dev/try/widget/NutritionTracker`

### Step 2: Add Widget Extension (2 minutes)

1. **File → New → Target**
2. **iOS → Widget Extension**
3. **Product Name**: `NutritionWidget`
4. **Include Configuration Intent**: `UNCHECKED` ❌
5. **Click Finish → Activate**

### Step 3: Configure App Groups (2 minutes)

**For Main App:**
1. **Select NutritionTracker target**
2. **Signing & Capabilities → + Capability → App Groups**
3. **Add group**: `group.com.yourname.nutritiontracker`
4. **Check the checkbox**

**For Widget:**
1. **Select NutritionWidget target** 
2. **Signing & Capabilities → + Capability → App Groups**
3. **Select the same group**
4. **Check the checkbox**

### Step 4: Copy Our Code (1 minute)

Run this command in Terminal:
```bash
cd /Users/tomercohen/dev/try/widget
./copy_files_to_xcode.sh
```

When prompted, enter the "yourname" part from your bundle identifier.

## 🚀 Running in Simulator

### Basic App Testing

1. **In Xcode, select "NutritionTracker" scheme** (top-left dropdown)
2. **Choose simulator**: "iPhone 15" (or any iPhone model)
3. **Press Cmd+R** to build and run
4. **Simulator will launch** showing your nutrition tracker app

### Test the App Features

**Add Food Items:**
1. **Tap the "+" button** (top right)
2. **Enter food name** (e.g., "Apple")
3. **Enter calories** (e.g., "95")
4. **Tap "Add Food Item"**
5. **Sheet should dismiss** and item appears in list

**Mark Items as Eaten:**
1. **Tap the circle icon** next to any food item
2. **Circle should fill with green checkmark**
3. **Calorie progress should update**
4. **Progress bar should reflect changes**

**View Progress:**
- **Top section shows**: "1,234 / 2,000 kcal"
- **Remaining calories**: "766 left" (green) or "234 over" (red)
- **Progress bar**: Visual representation of calories consumed

## 🏠 Testing the Widget

### Add Widget to Home Screen

1. **In Simulator, press Cmd+Shift+H** (go to home screen)
2. **Long press on empty space** on home screen
3. **Tap the "+" button** (top left when in jiggle mode)
4. **Search for "Nutrition"** in widget gallery
5. **Select your widget** and choose size:
   - **Small**: Shows calorie progress only
   - **Medium**: Shows progress + food items list
6. **Tap "Add Widget"**
7. **Press home button** to exit jiggle mode

### Test Widget Updates

1. **Open your app** (tap the app icon)
2. **Add a new food item**
3. **Mark it as eaten**
4. **Go back to home screen** (Cmd+Shift+H)
5. **Widget should update** within a few seconds showing new data

### Widget Tap Test

1. **Tap the widget** on home screen
2. **Should open your main app**

## 🧪 Advanced Testing Scenarios

### Test Multiple Food Items
```
Add these test items:
- Breakfast: Oatmeal (300 cal)
- Lunch: Sandwich (450 cal)  
- Snack: Apple (95 cal)
- Dinner: Salad (200 cal)

Mark some as eaten, leave others planned.
Total should update correctly.
```

### Test Edge Cases
- **Add item with 0 calories** (should show validation error)
- **Add item with empty name** (should show validation error)
- **Add many items** (test scrolling)
- **Delete items** (swipe left on items)

### Test Widget Sizes
- **Try both small and medium** widget sizes
- **Verify data shows correctly** in both
- **Test with different numbers** of food items

## 🔧 Troubleshooting

### App Won't Build
- **Check target membership**: Files should be added to correct targets
- **Check App Group IDs**: Must match exactly between app and widget
- **Clean build**: Product → Clean Build Folder, then try again

### Widget Not Updating
- **Force close and reopen** the simulator
- **Remove and re-add** the widget
- **Check App Group configuration**

### Simulator Issues
- **Reset simulator**: Device → Erase All Content and Settings
- **Try different device**: iPhone 14, iPhone 15 Pro, etc.
- **Check simulator version**: Should be iOS 17.0+

## 📱 Simulator Tips

### Useful Keyboard Shortcuts
- **Cmd+R**: Build and run
- **Cmd+Shift+H**: Home button
- **Cmd+Shift+H + H**: App switcher
- **Cmd+K**: Toggle software keyboard

### Simulate Different Scenarios
- **Device → Rotate Left/Right**: Test landscape mode
- **Features → Location**: Test location features (if added later)
- **Device → Shake**: Test shake gestures (if added later)

## 🎯 What You Should See

### Main App
- **Clean interface** with today's date
- **Progress bar** showing calorie consumption
- **List of food items** with toggle buttons
- **Add button** in navigation bar

### Widget (Small)
- **App icon** and "Nutrition" title
- **Current calories**: "1,234 / 2,000 kcal"
- **Remaining**: "766 left" or "234 over"
- **Progress bar**

### Widget (Medium)
- **All small widget content** plus
- **List of food items** (up to 4)
- **Checkmark/circle icons** showing status

---

## ✅ Success Indicators

You'll know everything is working when:
- ✅ App launches without errors
- ✅ You can add food items successfully
- ✅ Toggle buttons work (circle ↔ checkmark)
- ✅ Calorie totals update in real-time
- ✅ Widget appears on home screen
- ✅ Widget updates when app data changes
- ✅ Tapping widget opens the app

**The entire testing process should take about 15 minutes from start to finish!**