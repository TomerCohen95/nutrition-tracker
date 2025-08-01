# 🚀 Next Steps - Creating Your Nutrition Tracker Project

Xcode should now be open. Follow these steps exactly:

## Step 1: Create New Project in Xcode

1. **In Xcode, click "Create a new Xcode project"**
2. **Select "iOS" tab at the top**
3. **Choose "App" template**
4. **Click "Next"**

## Step 2: Configure Project Settings

Fill in these details:
- **Product Name**: `NutritionTracker`
- **Team**: (leave as is, or select your Apple ID if signed in)
- **Organization Identifier**: `com.yourname.nutritiontracker` (replace "yourname" with your actual name, e.g., `com.john.nutritiontracker`)
- **Bundle Identifier**: Will auto-populate based on Organization Identifier
- **Language**: `Swift`
- **Interface**: `SwiftUI`
- **Use Core Data**: `UNCHECKED` ❌ (we're using SwiftData instead)
- **Include Tests**: `CHECKED` ✅ (optional but recommended)

**Click "Next"**

## Step 3: Choose Save Location

1. **Navigate to this folder**: `/Users/tomercohen/dev/try/widget/NutritionTracker`
2. **Click "Create"**

## Step 4: Add Widget Extension

1. **In Xcode menu: File → New → Target**
2. **Select "iOS" tab**
3. **Choose "Widget Extension"**
4. **Click "Next"**
5. **Configure Widget:**
   - **Product Name**: `NutritionWidget`
   - **Include Configuration Intent**: `UNCHECKED` ❌
6. **Click "Finish"**
7. **When prompted "Activate NutritionWidget scheme?", click "Activate"**

## Step 5: Configure App Groups

### For Main App Target:
1. **Select "NutritionTracker" in project navigator (top-left)**
2. **Select "NutritionTracker" target (under TARGETS)**
3. **Click "Signing & Capabilities" tab**
4. **Click "+ Capability"**
5. **Search and select "App Groups"**
6. **Click the "+" button in App Groups section**
7. **Enter**: `group.com.yourname.nutritiontracker` (use the same "yourname" as your bundle identifier)
8. **Click "OK"**
9. **Check the checkbox next to the group**

### For Widget Target:
1. **Select "NutritionWidget" target (under TARGETS)**
2. **Click "Signing & Capabilities" tab**
3. **Click "+ Capability"**
4. **Search and select "App Groups"**
5. **Select the same group you just created**
6. **Check the checkbox**

## Step 6: Test Basic Setup

1. **Select "NutritionTracker" scheme (top-left dropdown)**
2. **Choose "iPhone 15" simulator**
3. **Press Cmd+R to build and run**
4. **You should see a basic "Hello, world!" app**

---

## ✅ When you've completed these steps, let me know and I'll help you add all the code files!

The next phase will be replacing the default files with our nutrition tracker code.

## 📝 Important Notes:

- **Remember your "yourname"** - you'll need to update it in the code files
- **App Group ID must match exactly** between main app and widget
- **Don't worry if there are warnings initially** - we'll fix them when adding our code

Let me know when you reach Step 6 and the basic app is running!