# 🧪 Task Management App - Testing Guide

## Quick Start Testing

### Prerequisites
1. Ensure your Node.js backend is running on `http://10.0.2.2:5000/api` (for Android emulator)
2. Have some test tasks in your backend database

---

## Test Scenario 1: Offline Task Update

**Purpose:** Verify tasks can be updated offline and UI refreshes immediately

### Steps:
1. ✅ **Launch the app** with internet connected
2. ✅ **Tap refresh** button to fetch tasks from API
3. ✅ **Verify tasks load** and show green cloud icons (synced)
4. ❌ **Turn off WiFi/Data** (enable Airplane mode)
5. ✅ **Tap on a task** to open detail screen
6. ✅ **Change status** from "pending" to "completed"
7. ✅ **Add remarks** like "Testing offline update"
8. ✅ **Tap Update** button

### Expected Results:
- ✅ UI immediately updates and returns to task list
- ✅ Modified task shows **red cloud icon** (unsynced)
- ✅ Status and remarks are updated in the list
- ✅ **NO CRASHES** even though device is offline

---

## Test Scenario 2: Auto-Sync When Back Online

**Purpose:** Verify pending changes automatically sync when connectivity restores

### Steps:
1. ✅ **Continue from Scenario 1** (should have unsynced tasks)
2. ✅ **Turn WiFi/Data back on** (disable Airplane mode)
3. ⏳ **Wait 2-3 seconds** for auto-sync to trigger

### Expected Results:
- ✅ Red cloud icons **automatically change to green**
- ✅ Tasks successfully synced to backend
- ✅ Check your backend database to confirm updates saved
- ✅ **NO CRASHES** during sync

---

## Test Scenario 3: Online Task Update

**Purpose:** Verify normal online updates work correctly

### Steps:
1. ✅ **Ensure internet is connected**
2. ✅ **Tap on a task** to open detail screen
3. ✅ **Change status** and add/modify remarks
4. ✅ **Tap Update** button

### Expected Results:
- ✅ UI immediately updates and returns to task list
- ✅ Modified task shows **green cloud icon** (synced)
- ✅ Changes are immediately saved to backend
- ✅ **NO CRASHES**

---

## Test Scenario 4: Error Handling (API Failure)

**Purpose:** Verify graceful degradation when API fails

### Steps:
1. ✅ **Ensure internet is connected**
2. ❌ **Stop your Node.js backend** (simulate API failure)
3. ✅ **Tap on a task** and modify it
4. ✅ **Tap Update** button

### Expected Results:
- ✅ Shows error message: "Update saved offline. Will sync when online."
- ✅ Task still updates in UI with **red cloud icon**
- ✅ After 2 seconds, UI refreshes to loaded state
- ✅ **NO CRASHES** - app handles error gracefully
- ⏳ **Restart backend**, task should auto-sync

---

## Test Scenario 5: Initial Load from Cache

**Purpose:** Verify offline-first behavior on app start

### Steps:
1. ✅ **Ensure app has cached tasks** (use app normally first)
2. ✅ **Kill the app completely**
3. ❌ **Turn off WiFi/Data** (enable Airplane mode)
4. ✅ **Launch the app**

### Expected Results:
- ✅ Tasks load **immediately from cache**
- ✅ All tasks show **red cloud icons** (offline)
- ✅ Can still view task details
- ✅ Can still update tasks offline
- ✅ **NO CRASHES OR ERRORS**

---

## Test Scenario 6: Pull to Refresh

**Purpose:** Verify manual sync works correctly

### Steps:
1. ✅ **Ensure internet is connected**
2. ✅ **Tap the refresh button** in AppBar
3. ⏳ **Wait for loading indicator**

### Expected Results:
- ✅ Shows **CircularProgressIndicator** while loading
- ✅ Tasks refresh from backend
- ✅ All synced tasks show **green cloud icons**
- ✅ UI updates with latest data
- ✅ **NO CRASHES**

---

## Test Scenario 7: Memory Leak Check

**Purpose:** Verify connectivity listener is properly disposed

### Steps:
1. ✅ **Navigate to task list screen**
2. ✅ **Navigate away** (if you have multiple screens)
3. ✅ **Navigate back to task list**
4. ✅ **Repeat 5-10 times**
5. ⏳ **Check device memory usage** (via Android Studio Profiler)

### Expected Results:
- ✅ Memory usage remains **stable**
- ✅ No continuous memory increase
- ✅ App remains **responsive**
- ✅ **NO CRASHES OR SLOWDOWNS**

---

## Common Issues & Solutions

### ❌ Issue: "Failed to fetch tasks" error
**Solution:** 
- Verify backend is running on correct URL
- Check `dio_client.dart` baseUrl matches your backend
- For Android emulator: use `http://10.0.2.2:5000/api`
- For physical device: use your computer's IP address

### ❌ Issue: Tasks not syncing after coming online
**Solution:**
- Tasks should auto-sync within 2-3 seconds
- If not, check console logs for errors
- Verify connectivity listener is working (check debug logs)

### ❌ Issue: UI not updating after task modification
**Solution:**
- This was the main bug we fixed!
- If still happening, check that `loadLocalTasks()` is being called
- Verify `state = TaskLoaded(tasks)` is executing

---

## Debug Tips

### Enable Debug Logging
The fixed code includes `print()` statements for errors:
- Check console for: "Failed to sync task..." messages
- Check for: "Sync error..." messages

### Check Hive Storage
```dart
// Add temporary debug code in loadLocalTasks()
print('Loaded ${localTasks.length} tasks from cache');
print('Tasks: ${localTasks.map((t) => t.title).join(', ')}');
```

### Verify Connectivity Detection
```dart
// Add in updateTask()
print('Connectivity result: $connectivityResult');
print('Is online: $isOnline');
```

---

## Success Criteria

Your app is working correctly if:

- ✅ **Offline updates** save locally and show red cloud icon
- ✅ **Online updates** sync immediately and show green cloud icon
- ✅ **Auto-sync** happens when connectivity restores
- ✅ **UI refreshes** immediately after any update
- ✅ **Error messages** appear when API fails (not crashes)
- ✅ **No memory leaks** during repeated navigation
- ✅ **NO CRASHES** in any scenario

---

## What Was Fixed (Summary)

All 7 bugs have been fixed:
1. ✅ Type safety with generic `List<TaskModel>`
2. ✅ Removed unused import
3. ✅ Fixed connectivity detection for connectivity_plus 5.x
4. ✅ Added error handling for API calls
5. ✅ Isolated sync failures (one failure doesn't block others)
6. ✅ Added dispose method (prevents memory leaks)
7. ✅ Added null safety for Hive operations

**Result:** Production-ready code with robust error handling and offline support! 🎉
