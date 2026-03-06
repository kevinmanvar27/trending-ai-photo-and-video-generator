# Contact Sync - Data Flow Documentation

## API Endpoint
```
POST https://trends.rektech.work/api/contacts/store
```

## Request Headers
```
Authorization: Bearer {user_auth_token}
Content-Type: application/json
```

## Request Body Format
```json
{
  "contacts": [
    {
      "name": "John Doe",
      "phone_number": "+1234567890"
    },
    {
      "name": "Jane Smith",
      "phone_number": "+0987654321"
    },
    {
      "name": "Bob Wilson",
      "phone_number": "9876543210"
    }
  ]
}
```

## Expected Response (Success)
```json
{
  "success": true,
  "message": "Contacts saved successfully",
  "data": {
    "saved_count": 3
  }
}
```

## Expected Response (Error)
```json
{
  "success": false,
  "message": "Error message here",
  "errors": {}
}
```

---

## Implementation Details

### 1. Contact Reading Process

**Step 1: Request Permission**
```dart
// Uses flutter_contacts package
final hasPermission = await FlutterContacts.requestPermission();
```

**Step 2: Read All Contacts**
```dart
final contacts = await FlutterContacts.getContacts(
  withProperties: true,  // Include phone numbers, emails, etc.
  withPhoto: false,      // Don't load photos (faster)
);
```

**Step 3: Extract Phone Numbers**
```dart
// For each contact, extract ALL phone numbers
for (var contact in contacts) {
  if (contact.phones.isNotEmpty) {
    final name = contact.displayName.isNotEmpty 
        ? contact.displayName 
        : 'Unknown';
    
    // Add each phone number as separate entry
    for (var phone in contact.phones) {
      contactsList.add({
        'name': name,
        'phone_number': phone.number,
      });
    }
  }
}
```

### 2. Data Transformation

**Example: Contact with Multiple Numbers**

Device Contact:
```
Name: John Doe
Phone 1: +1 (555) 123-4567 (Mobile)
Phone 2: +1 (555) 987-6543 (Home)
Phone 3: +1 (555) 111-2222 (Work)
```

Transformed to API Format:
```json
[
  {
    "name": "John Doe",
    "phone_number": "+1 (555) 123-4567"
  },
  {
    "name": "John Doe",
    "phone_number": "+1 (555) 987-6543"
  },
  {
    "name": "John Doe",
    "phone_number": "+1 (555) 111-2222"
  }
]
```

**Why?** Backend can handle duplicates and will store unique combinations of user_id + phone_number.

### 3. Phone Number Formats Handled

The app sends phone numbers **exactly as stored** on the device:

✅ **Supported Formats:**
- International: `+1234567890`
- With spaces: `+1 234 567 890`
- With dashes: `+1-234-567-890`
- With parentheses: `+1 (234) 567-890`
- Local format: `9876543210`
- With country code: `+91 9876543210`

**Note:** Backend should normalize these formats for matching.

---

## Console Logs (Expected Output)

### Successful Sync:
```
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
```

### Error Cases:

**Permission Denied:**
```
📱 Requesting contact permission...
❌ Contact permission denied
❌ Contact sync failed: Permission denied
```

**No Contacts Found:**
```
📱 Found 0 contacts on device
✅ Extracted 0 contact entries with phone numbers
⚠️ No contacts found on device
```

**API Error:**
```
📤 Sending 245 contacts to backend...
📥 Response Status: 500
📥 Response Data: {success: false, message: Internal server error}
❌ Failed to store contacts: {success: false, message: Internal server error}
```

**Network Error:**
```
📤 Sending 245 contacts to backend...
❌ Error storing contacts to backend: DioException [connection timeout]
```

---

## Backend Database Schema (Expected)

### Table: `user_contacts`
```sql
CREATE TABLE user_contacts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_user_phone (user_id, phone_number),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_phone_number (phone_number)
);
```

### Table: `user_contact_sync`
```sql
CREATE TABLE user_contact_sync (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    last_sync_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_contacts INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
```

### Backend Logic (Expected):

1. **Validate Request:**
   - Check auth token
   - Validate contacts array format
   - Ensure name and phone_number fields exist

2. **Process Contacts:**
   ```php
   foreach ($contacts as $contact) {
       // Insert or update (upsert)
       UserContact::updateOrCreate(
           [
               'user_id' => $userId,
               'phone_number' => $contact['phone_number']
           ],
           [
               'name' => $contact['name']
           ]
       );
   }
   ```

3. **Update Sync History:**
   ```php
   UserContactSync::updateOrCreate(
       ['user_id' => $userId],
       [
           'last_sync_at' => now(),
           'total_contacts' => count($contacts)
       ]
   );
   ```

4. **Return Response:**
   ```php
   return response()->json([
       'success' => true,
       'message' => 'Contacts saved successfully',
       'data' => [
           'saved_count' => count($contacts)
       ]
   ]);
   ```

---

## Data Privacy & Security

### Client-Side (Flutter App):
✅ Permission requested before reading contacts  
✅ User must explicitly tap "Sync Contacts" button  
✅ Privacy notice displayed on sync screen  
✅ Auth token required for API access  
✅ HTTPS encryption for data transmission  

### Server-Side (Backend):
✅ Auth token validation  
✅ Per-user contact isolation (user_id foreign key)  
✅ Unique constraint prevents duplicates  
✅ Secure database storage  
✅ No sharing with third parties  

---

## Testing Checklist

### ✅ Data Integrity Tests:
- [ ] All contacts are read from device
- [ ] Contacts with multiple numbers send all numbers
- [ ] Contact names are preserved correctly
- [ ] Phone numbers maintain original format
- [ ] Empty/null names default to "Unknown"
- [ ] Contacts without phone numbers are skipped

### ✅ API Tests:
- [ ] Request body matches expected format
- [ ] Auth token is included in headers
- [ ] Response is parsed correctly
- [ ] Success response updates UI
- [ ] Error response shows error message
- [ ] Network errors are handled gracefully

### ✅ Backend Tests:
- [ ] Contacts are stored in database
- [ ] Duplicates are handled (upsert)
- [ ] Saved count matches sent count
- [ ] Sync history is updated
- [ ] Invalid data is rejected
- [ ] Unauthorized requests are blocked

---

## Performance Considerations

### Small Dataset (< 100 contacts):
- Read time: 1-2 seconds
- Upload time: 2-3 seconds
- **Total: 3-5 seconds**

### Medium Dataset (100-500 contacts):
- Read time: 2-3 seconds
- Upload time: 3-5 seconds
- **Total: 5-8 seconds**

### Large Dataset (500-1000+ contacts):
- Read time: 3-5 seconds
- Upload time: 5-10 seconds
- **Total: 8-15 seconds**

### Optimization Tips:
1. **Batch Processing:** Backend should handle large arrays efficiently
2. **Compression:** Consider gzip compression for large payloads
3. **Pagination:** For 5000+ contacts, consider splitting into batches
4. **Background Sync:** Use WorkManager for periodic syncs

---

## Error Handling Matrix

| Error Type | Client Action | User Message |
|------------|---------------|--------------|
| Permission Denied | Stop sync | "Permission required to sync contacts" |
| No Contacts | Stop sync | "No contacts found on device" |
| Network Error | Retry option | "Network error. Please try again" |
| API Error (4xx) | Show error | "Failed to sync. Please try again" |
| API Error (5xx) | Retry option | "Server error. Please try again later" |
| Token Expired | Redirect to login | "Session expired. Please login again" |
| Unknown Error | Show error | "An error occurred. Please try again" |

---

## Future Enhancements

### Phase 2:
- [ ] Automatic sync on login
- [ ] Periodic background sync (daily)
- [ ] Sync progress indicator (X/Y contacts)
- [ ] Contact matching (find friends on app)

### Phase 3:
- [ ] Selective sync (choose contacts)
- [ ] Contact groups sync
- [ ] Email addresses sync
- [ ] Contact photos sync (optional)

### Phase 4:
- [ ] Two-way sync (update device contacts)
- [ ] Conflict resolution
- [ ] Sync history view
- [ ] Export contacts feature

---

**Document Version:** 1.0  
**Last Updated:** January 2024  
**Status:** ✅ Implementation Complete
