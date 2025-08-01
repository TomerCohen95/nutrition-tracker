# 🚀 Final Steps to iOS Simulator

All your code is now in the Xcode project! Just 2 more steps:

## Step 1: Configure App Groups (3 minutes)

**In Xcode:**

### For Main App:
1. **Click "NutritionTracker"** in the left project navigator (top item)
2. **Select "NutritionTracker" target** (under TARGETS section)
3. **Click "Signing & Capabilities" tab**
4. **Click "+ Capability"** button
5. **Search and select "App Groups"**
6. **Click the "+" button** in the App Groups section
7. **Enter**: `group.com.tomercoden.nutritiontracker`
8. **Click "OK"**
9. **Check the checkbox** next to the group

### For Widget:
1. **Select "NutritionWidget" target** (under TARGETS section)
2. **Click "Signing & Capabilities" tab**
3. **Click "+ Capability"** button
4. **Search and select "App Groups"**
5. **Select the same group**: `group.com.tomercoden.nutritiontracker`
6. **Check the checkbox**

## Step 2: Run in Simulator (1 minute)

1. **Select "NutritionTracker" scheme** (top-left dropdown)
2. **Choose "iPhone 15" simulator** (or any iPhone)
3. **Press Cmd+R** to build and run

## 🎉 Success!

The iOS Simulator will launch with your nutrition tracker app:

### Test Features:
- **Add Food**: Tap the **+** button → Enter name and calories
- **Mark as Eaten**: Tap circle icons to mark items as eaten
- **View Progress**: See calorie totals and progress bar update
- **Delete Items**: Swipe left on items to delete

### Test Widget:
1. **Go to home screen**: Press **Cmd+Shift+H**
2. **Long press empty space** on home screen
3. **Tap "+"** (top left when in jiggle mode)
4. **Search "Nutrition"**
5. **Add widget** (choose small or medium size)
6. **Test updates**: Add/edit items in app, widget should update

## 🔧 Troubleshooting

**If you see build errors:**
- Make sure all files are added to their targets
- Clean build: **Product → Clean Build Folder**
- Try building again

**If App Groups aren't working:**
- Double-check the group ID is exactly: `group.com.tomercoden.nutritiontracker`
- Make sure both targets have the same group selected

---

**You're seconds away from testing your nutrition tracker in the simulator!**