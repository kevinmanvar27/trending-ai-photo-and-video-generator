import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'api_service.dart';
import 'api_config.dart';

class ContactService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  
  final isSyncing = false.obs;
  final lastSyncTime = Rxn<DateTime>();
  final totalContactsSynced = 0.obs;
  
  // Request contact permission
  Future<bool> requestContactPermission() async {
    try {
      print('📱 Requesting contact permission...');
      
      PermissionStatus status = await Permission.contacts.request();
      
      if (status.isGranted) {
        print('✅ Contact permission granted');
        return true;
      } else if (status.isDenied) {
        print('❌ Contact permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('⚠️ Contact permission permanently denied');
        // Open app settings
        await openAppSettings();
        return false;
      }
      
      return false;
    } catch (e) {
      print('❌ Error requesting contact permission: $e');
      return false;
    }
  }
  
  // Check if permission is already granted
  Future<bool> hasContactPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }
  
  // Get all contacts from device
  Future<List<Map<String, String>>> getDeviceContacts() async {
    try {
      print('📱 Reading contacts from device...');
      
      // Check permission first
      if (!await FlutterContacts.requestPermission()) {
        print('❌ Contact permission not granted');
        return [];
      }
      
      // Get all contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      print('📱 Found ${contacts.length} contacts on device');
      
      List<Map<String, String>> contactsList = [];
      
      for (var contact in contacts) {
        // Only add contacts with phone numbers
        if (contact.phones.isNotEmpty) {
          final name = contact.displayName.isNotEmpty 
              ? contact.displayName 
              : 'Unknown';
          
          // Add each phone number as a separate contact entry
          for (var phone in contact.phones) {
            if (phone.number.isNotEmpty) {
              contactsList.add({
                'name': name,
                'phone_number': phone.number,
              });
            }
          }
        }
      }
      
      print('✅ Extracted ${contactsList.length} contact entries with phone numbers');
      print('📊 From ${contacts.length} unique contacts');
      return contactsList;
      
    } catch (e) {
      print('❌ Error reading contacts: $e');
      return [];
    }
  }
  
  // Send contacts to backend
  Future<bool> storeContactsToBackend(List<Map<String, String>> contacts) async {
    try {
      if (contacts.isEmpty) {
        print('⚠️ No contacts to sync');
        return false;
      }
      
      print('📤 Sending ${contacts.length} contacts to backend...');
      print('📍 API Endpoint: ${ApiConfig.contactsStore}');
      
      // Show sample of contacts being sent (first 3)
      print('📋 Sample contacts:');
      for (int i = 0; i < (contacts.length > 3 ? 3 : contacts.length); i++) {
        print('   ${i + 1}. ${contacts[i]['name']} - ${contacts[i]['phone_number']}');
      }
      if (contacts.length > 3) {
        print('   ... and ${contacts.length - 3} more');
      }
      
      print('🔵 Making API call...');
      final response = await _apiService.post(
        ApiConfig.contactsStore,
        data: {
          'contacts': contacts,
        },
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final savedCount = response.data['data']['saved_count'] ?? 0;
        print('✅ Contacts stored successfully: $savedCount contacts');
        
        totalContactsSynced.value = savedCount;
        lastSyncTime.value = DateTime.now();
        
        return true;
      } else {
        print('❌ Failed to store contacts: ${response.data}');
        return false;
      }
      
    } catch (e, stackTrace) {
      print('❌ Error storing contacts to backend: $e');
      print('❌ Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Complete sync flow: Request permission → Get contacts → Send to backend
  Future<bool> syncContacts() async {
    try {
      isSyncing.value = true;
      
      print('\n╔════════════════════════════════════════════════════════════════');
      print('║ 📱 CONTACT SYNC STARTED');
      print('╚════════════════════════════════════════════════════════════════\n');
      
      // Step 1: Request permission
      print('📍 Step 1: Requesting permission...');
      final hasPermission = await requestContactPermission();
      
      if (!hasPermission) {
        print('❌ Contact sync failed: Permission denied');
        isSyncing.value = false;
        return false;
      }
      
      // Step 2: Get contacts from device
      print('📍 Step 2: Reading contacts from device...');
      final contacts = await getDeviceContacts();
      
      if (contacts.isEmpty) {
        print('⚠️ No contacts found on device');
        isSyncing.value = false;
        return false;
      }
      
      // Step 3: Send to backend
      print('📍 Step 3: Sending contacts to backend...');
      final success = await storeContactsToBackend(contacts);
      
      if (success) {
        print('\n╔════════════════════════════════════════════════════════════════');
        print('║ ✅ CONTACT SYNC COMPLETED');
        print('╠════════════════════════════════════════════════════════════════');
        print('║ Total Contacts: ${contacts.length}');
        print('║ Synced: ${totalContactsSynced.value}');
        print('║ Time: ${lastSyncTime.value}');
        print('╚════════════════════════════════════════════════════════════════\n');
      }
      
      isSyncing.value = false;
      return success;
      
    } catch (e, stackTrace) {
      print('❌ Contact sync error: $e');
      print('❌ Stack trace: $stackTrace');
      isSyncing.value = false;
      return false;
    }
  }
  
  // Get sync status text
  String getSyncStatusText() {
    if (lastSyncTime.value == null) {
      return 'Not synced yet';
    }
    
    final now = DateTime.now();
    final diff = now.difference(lastSyncTime.value!);
    
    if (diff.inMinutes < 1) {
      return 'Synced just now';
    } else if (diff.inHours < 1) {
      return 'Synced ${diff.inMinutes} minutes ago';
    } else if (diff.inDays < 1) {
      return 'Synced ${diff.inHours} hours ago';
    } else {
      return 'Synced ${diff.inDays} days ago';
    }
  }
}
