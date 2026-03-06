# Contact Sync Debugging Guide

## Current Status: Adding Debug Logs

### Changes Made for Debugging:

1. **Fixed ApiService initialization** in `contact_service.dart`
   - Changed from `ApiService()` to `Get.find<ApiService>()`
   - This ensures we use the authenticated API service instance

2. **Added debug logs throughout the flow:**

#### Profile View (Button Tap)
```
🔵 Profile: Sync Contacts button tapped
🔵 Profile: Navigating to /contact-sync
```

#### Contact Sync View (Screen Load)
```
🔵 ContactSyncView: Building view
```

#### Contact Sync View (Button Press)
```
🔵 ContactSyncView: Sync button pressed
```

#### Contact Sync Controller
```
🔵 ContactSyncController: syncContacts() called
🔵 ContactSyncController: Calling _contactService.syncContacts()...
🔵 ContactSyncController: syncContacts() returned: true/false
🔵 ContactSyncController: syncContacts() finished
```

#### Contact Service (Main Flow)
```
╔════════════════════════════════════════════════════════════════
║ 📱 CONTACT SYNC STARTED
╚════════════════════════════════════════════════════════════════

📍 Step 1: Requesting permission...
📱 Requesting contact permission...
✅ Contact permission granted (or ❌ denied)

📍 Step 2: Reading contacts from device...
📱 Reading contacts from device...
📱 Found X contacts on device
✅ Extracted Y contact entries with phone numbers
📊 From X unique contacts

📍 Step 3: Sending contacts to backend...
📤 Sending Y contacts to backend...
📍 API Endpoint: /contacts/store
📋 Sample contacts:
   1. Name - Phone
   2. Name - Phone
   3. Name - Phone
   ... and Y more

🔵 Making API call...
📥 Response Status: 200
📥 Response Data: {...}
✅ Contacts stored successfully: Y contacts

╔════════════════════════════════════════════════════════════════
║ ✅ CONTACT SYNC COMPLETED
╠════════════════════════════════════════════════════════════════
║ Total Contacts: Y
║ Synced: Y
║ Time: [timestamp]
╚════════════════════════════════════════════════════════════════
```

---

## Testing Steps:

1. **Run the app:**
   ```bash
   flutter run -d RZCW3190RXM
   ```

2. **Navigate to Profile:**
   - Open app
   - Login if needed
   - Go to Profile screen
   - Look for "Sync Contacts" button

3. **Tap "Sync Contacts":**
   - Watch console for: `🔵 Profile: Sync Contacts button tapped`
   - Should navigate to Contact Sync screen

4. **On Contact Sync Screen:**
   - Watch console for: `🔵 ContactSyncView: Building view`
   - Tap "Sync Contacts" button
   - Watch console for: `🔵 ContactSyncView: Sync button pressed`

5. **Watch the sync flow:**
   - Permission request
   - Contact reading
   - API call
   - Response handling

---

## Common Issues & Solutions:

### Issue 1: Button tap not working
**Symptoms:** No logs when tapping button
**Solution:** Check if InkWell is responding, verify button is visible

### Issue 2: Navigation fails
**Symptoms:** `🔵 Profile: Sync Contacts button tapped` but no screen change
**Solution:** Check if route is registered in app_pages.dart

### Issue 3: Controller not found
**Symptoms:** Error: `Get.find<ContactSyncController>()` fails
**Solution:** Verify binding is added to the route

### Issue 4: Permission denied
**Symptoms:** `❌ Contact permission denied`
**Solution:** 
- Check AndroidManifest.xml has READ_CONTACTS permission
- Try manually granting permission in device settings

### Issue 5: No contacts found
**Symptoms:** `⚠️ No contacts found on device`
**Solution:**
- Verify device has contacts
- Check contacts have phone numbers
- Verify permission was granted

### Issue 6: API call fails
**Symptoms:** `❌ Error storing contacts to backend`
**Solutions:**
- Check internet connection
- Verify auth token is valid (check ApiService logs)
- Verify backend endpoint is correct: `/contacts/store`
- Check backend logs for errors

### Issue 7: ApiService not found
**Symptoms:** Error: `Get.find<ApiService>()` fails
**Solution:** Verify ApiServiceInitializer.init() is called in main.dart

---

## Expected Console Output (Success):

```
🔵 Profile: Sync Contacts button tapped
🔵 Profile: Navigating to /contact-sync
🔵 ContactSyncView: Building view
🔵 ContactSyncView: Sync button pressed
🔵 ContactSyncController: syncContacts() called
🔵 ContactSyncController: Calling _contactService.syncContacts()...

╔════════════════════════════════════════════════════════════════
║ 📱 CONTACT SYNC STARTED
╚════════════════════════════════════════════════════════════════

📍 Step 1: Requesting permission...
📱 Requesting contact permission...
✅ Contact permission granted

📍 Step 2: Reading contacts from device...
📱 Reading contacts from device...
📱 Found 150 contacts on device
✅ Extracted 245 contact entries with phone numbers
📊 From 150 unique contacts

📍 Step 3: Sending contacts to backend...
📤 Sending 245 contacts to backend...
📍 API Endpoint: /contacts/store
📋 Sample contacts:
   1. John Doe - +1234567890
   2. Jane Smith - +0987654321
   3. Bob Wilson - 9876543210
   ... and 242 more

🔵 Making API call...
📥 Response Status: 200
📥 Response Data: {success: true, message: Contacts saved successfully, data: {saved_count: 245}}
✅ Contacts stored successfully: 245 contacts

╔════════════════════════════════════════════════════════════════
║ ✅ CONTACT SYNC COMPLETED
╠════════════════════════════════════════════════════════════════
║ Total Contacts: 245
║ Synced: 245
║ Time: 2024-01-15 14:30:25.123
╚════════════════════════════════════════════════════════════════

🔵 ContactSyncController: syncContacts() returned: true
🔵 ContactSyncController: syncContacts() finished
```

---

## Next Steps:

1. Run the app and test
2. Share the console output
3. Identify where the flow stops
4. Fix the specific issue

---

**Last Updated:** 2024-01-15
