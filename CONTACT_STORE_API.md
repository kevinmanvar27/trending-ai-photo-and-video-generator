# Contact Store API - Simple Documentation

## 📱 Overview
Ye API Flutter app se user ke device ke contacts receive karke database mein save kar deta hai.

---

## 🔗 API Endpoint

**Endpoint:** `POST /api/contacts/store`

**Authentication:** Bearer Token required

**Header:**
```
Authorization: Bearer {your_token}
Content-Type: application/json
```

---

## 📤 Request Format

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

**Fields:**
- `contacts` (required, array): Array of contact objects
- `contacts[].name` (optional, string): Contact ka naam
- `contacts[].phone_number` (required, string): Contact ka phone number

---

## 📥 Response Format

### Success Response (200)
```json
{
  "success": true,
  "message": "Contacts saved successfully",
  "data": {
    "saved_count": 3
  }
}
```

### Error Response (422) - Validation Failed
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "contacts": ["The contacts field is required."],
    "contacts.0.phone_number": ["The phone number field is required."]
  }
}
```

### Error Response (500) - Server Error
```json
{
  "success": false,
  "message": "Failed to save contacts",
  "error": "Error details..."
}
```

---

## 📱 Flutter Implementation

### 1. Add Permission (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

### 2. Add Package (pubspec.yaml)
```yaml
dependencies:
  contacts_service: ^0.6.3
  permission_handler: ^10.4.3
  http: ^1.1.0
```

### 3. Request Permission & Get Contacts
```dart
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Request permission
Future<bool> requestContactPermission() async {
  PermissionStatus permission = await Permission.contacts.request();
  return permission.isGranted;
}

// Get contacts from device
Future<List<Map<String, String>>> getDeviceContacts() async {
  List<Map<String, String>> contactsList = [];
  
  Iterable<Contact> contacts = await ContactsService.getContacts();
  
  for (var contact in contacts) {
    if (contact.phones != null && contact.phones!.isNotEmpty) {
      contactsList.add({
        'name': contact.displayName ?? '',
        'phone_number': contact.phones!.first.value ?? '',
      });
    }
  }
  
  return contactsList;
}

// Send contacts to API
Future<void> storeContactsToBackend(List<Map<String, String>> contacts) async {
  final url = Uri.parse('https://your-domain.com/api/contacts/store');
  final token = 'YOUR_AUTH_TOKEN'; // Get from SharedPreferences/Secure Storage
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'contacts': contacts,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Success: ${data['message']}');
      print('Saved: ${data['data']['saved_count']} contacts');
    } else {
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}

// Complete flow
Future<void> syncContacts() async {
  // 1. Request permission
  bool hasPermission = await requestContactPermission();
  
  if (!hasPermission) {
    print('Contact permission denied');
    return;
  }
  
  // 2. Get contacts
  List<Map<String, String>> contacts = await getDeviceContacts();
  print('Found ${contacts.length} contacts');
  
  // 3. Send to backend
  await storeContactsToBackend(contacts);
}
```

### 4. Call from UI
```dart
ElevatedButton(
  onPressed: () async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    // Sync contacts
    await syncContacts();
    
    // Hide loading
    Navigator.pop(context);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contacts synced successfully!')),
    );
  },
  child: Text('Sync Contacts'),
)
```

---

## 🧪 Testing with cURL

```bash
curl -X POST http://localhost/api/contacts/store \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "contacts": [
      {
        "name": "Test User",
        "phone_number": "+1234567890"
      },
      {
        "name": "Another User",
        "phone_number": "9876543210"
      }
    ]
  }'
```

---

## 🗄️ Database Tables

### user_contacts
Stores all contacts from user's device

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | User ID (foreign key) |
| name | varchar(255) | Contact name |
| phone_number | varchar(20) | Contact phone number |
| created_at | timestamp | Created time |
| updated_at | timestamp | Updated time |

**Unique Constraint:** (user_id, phone_number) - Prevents duplicate contacts

### user_contact_sync
Tracks when contacts were last synced

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | User ID (foreign key, unique) |
| last_synced_at | timestamp | Last sync time |
| total_contacts | integer | Total contacts count |
| created_at | timestamp | Created time |
| updated_at | timestamp | Updated time |

---

## ✨ Features

- ✅ Simple single endpoint
- ✅ Stores contacts in database
- ✅ Phone number normalization (removes spaces/dashes)
- ✅ Prevents duplicate contacts
- ✅ Tracks sync status
- ✅ User-specific data (isolated by user_id)
- ✅ Auto-updates if contact already exists

---

## 🔐 Security

- ✅ Authentication required (Bearer token)
- ✅ User can only store their own contacts
- ✅ Input validation
- ✅ SQL injection prevention (using query builder)

---

## 📋 Complete Flow

```
1. User opens Flutter app
   ↓
2. App requests contact permission
   ↓
3. User grants permission
   ↓
4. App reads contacts from device
   ↓
5. App sends contacts to POST /api/contacts/store
   ↓
6. Backend saves contacts in database
   ↓
7. Backend returns success response
   ↓
8. App shows "Contacts synced successfully!"
```

---

## ✅ That's It!

Bas itna hi! Ek simple API jo Flutter app se contacts receive kare aur database mein save kar de.

**API URL:** `POST /api/contacts/store`

**Done! 🎉**
