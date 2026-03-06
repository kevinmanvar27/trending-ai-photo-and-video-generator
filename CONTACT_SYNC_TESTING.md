# Contact Sync Testing Guide

## Quick Test Steps

### 1. **Navigate to Contact Sync Screen**
```
1. Open the app
2. Login with your account (devlopers1908@gmail.com)
3. Tap the hamburger menu (or navigate to Profile)
4. Scroll down to find "Sync Contacts" button
5. Tap "Sync Contacts"
```

### 2. **Test Permission Flow**
```
Expected: System permission dialog appears
Actions:
  - Tap "Allow" → Should proceed to sync
  - Tap "Deny" → Should show error message
```

### 3. **Test Successful Sync**
```
Expected behavior:
1. Button text changes to "Syncing Contacts..."
2. Loading spinner appears
3. After a few seconds:
   - Success snackbar: "✅ Contacts synced successfully!"
   - Sync status card appears showing:
     * "Synced just now"
     * "Contacts Synced: X" (where X is the count)
```

### 4. **Test Sync Again**
```
Expected behavior:
1. Tap "Sync Contacts" button again
2. Status card updates with new sync time
3. Contact count may change if contacts were added/removed
```

### 5. **Check Console Logs**
```
Look for these logs in the console:
╔════════════════════════════════════════════════════════════════
║ 📱 CONTACT SYNC STARTED
╚════════════════════════════════════════════════════════════════

📍 Step 1: Requesting permission...
✅ Contact permission granted

📍 Step 2: Reading contacts from device...
📱 Found X contacts on device
✅ Extracted X contacts with phone numbers

📍 Step 3: Sending contacts to backend...
✅ Contacts stored successfully: X contacts

╔════════════════════════════════════════════════════════════════
║ ✅ CONTACT SYNC COMPLETED
╠════════════════════════════════════════════════════════════════
║ Total Contacts: X
║ Synced: X
║ Time: [timestamp]
╚════════════════════════════════════════════════════════════════
```

---

## Troubleshooting

### Issue: Permission dialog doesn't appear
**Solution:** 
- Check if permission was already granted
- Go to Settings → Apps → Trends → Permissions → Enable Contacts

### Issue: "No contacts found on device"
**Solution:**
- Verify your device has contacts
- Ensure contacts have phone numbers
- Check if contacts app has proper data

### Issue: API error / Network error
**Solution:**
- Check internet connection
- Verify backend is running: https://trends.rektech.work/api
- Check if auth token is valid (try re-login)

### Issue: App crashes on sync
**Solution:**
- Check console logs for error details
- Verify flutter_contacts package is installed
- Ensure Android permissions are in manifest

---

## Backend Verification

### Check if contacts were stored:
```sql
-- Query user_contacts table
SELECT * FROM user_contacts 
WHERE user_id = [your_user_id]
ORDER BY created_at DESC;

-- Check sync history
SELECT * FROM user_contact_sync
WHERE user_id = [your_user_id]
ORDER BY last_sync_at DESC;
```

### Expected API Response:
```json
{
  "success": true,
  "message": "Contacts saved successfully",
  "data": {
    "saved_count": 145
  }
}
```

---

## Test Scenarios

### ✅ Happy Path
- [x] Permission granted on first request
- [x] Contacts read successfully
- [x] API call succeeds
- [x] UI updates correctly
- [x] Sync status displays

### ⚠️ Error Cases
- [ ] Permission denied → Shows error message
- [ ] No contacts on device → Shows warning
- [ ] Network error → Shows error snackbar
- [ ] API error → Shows error message
- [ ] Token expired → Redirects to login

### 🔄 Edge Cases
- [ ] Sync while already syncing → Button disabled
- [ ] Sync with 0 contacts → Shows warning
- [ ] Sync with 1000+ contacts → Should handle large data
- [ ] Sync after logout → Should require re-login
- [ ] Sync with invalid token → Should show auth error

---

## Performance Metrics

**Expected Performance:**
- Permission request: < 1 second
- Read 100 contacts: 1-2 seconds
- API upload 100 contacts: 2-3 seconds
- Total sync time: 3-6 seconds

**Large Dataset (1000+ contacts):**
- Read contacts: 3-5 seconds
- API upload: 5-10 seconds
- Total: 8-15 seconds

---

## Success Criteria

✅ **Feature is working if:**
1. Permission dialog appears and can be granted
2. Contacts are read from device
3. Contacts are sent to backend successfully
4. Success message appears
5. Sync status card displays correctly
6. Subsequent syncs update the status
7. No crashes or errors in console

---

## Next Steps After Testing

1. **If successful:**
   - Consider adding automatic sync on login
   - Add periodic background sync
   - Implement contact matching feature

2. **If issues found:**
   - Check console logs for errors
   - Verify backend API is working
   - Test on different devices
   - Check network connectivity

---

**Testing Date:** _____________  
**Tester:** _____________  
**Device:** _____________  
**Result:** ✅ Pass / ❌ Fail  
**Notes:** _____________
