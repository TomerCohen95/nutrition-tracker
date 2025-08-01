# Xcode Project Setup Instructions

## After Xcode Installation Complete:

### 1. Create New Project
1. Open Xcode
2. Choose "Create a new Xcode project"
3. Select **iOS** → **App**
4. Fill in project details:
   - **Product Name**: `NutritionTracker`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Use Core Data**: `NO` (we'll use SwiftData instead)
   - **Bundle Identifier**: `com.yourname.nutritiontracker` (replace 'yourname' with your name)

### 2. Add Widget Extension
1. In Xcode, go to **File** → **New** → **Target**
2. Select **iOS** → **Widget Extension**
3. Name it: `NutritionWidget`
4. **Include Configuration Intent**: `NO` (keep it simple for MVP)
5. Click **Finish**
6. When prompted "Activate scheme?", click **Activate**

### 3. Configure App Groups
1. Select your main app target (`NutritionTracker`)
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** → **App Groups**
4. Click **+** to add a new group
5. Enter: `group.com.yourname.nutritiontracker` (same yourname as bundle ID)
6. Check the checkbox next to the group

7. Now select the **Widget Extension** target (`NutritionWidget`)
8. Go to **Signing & Capabilities** tab
9. Click **+ Capability** → **App Groups**
10. Select the same group you just created
11. Check the checkbox

### 4. Test Basic Setup
1. Select **NutritionTracker** scheme (top left in Xcode)
2. Choose an iPhone simulator (like iPhone 15)
3. Press **Cmd+R** to run
4. You should see a basic "Hello, world!" app

**Let me know when you've completed these steps and I'll provide all the code files!**