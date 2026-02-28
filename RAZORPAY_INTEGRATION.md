# Razorpay Integration Guide

## Overview
This app now has Razorpay payment gateway integrated for purchasing credits.

## Test Credentials
- **Key ID**: `rzp_test_Go3jN8rdNmRJ7P`
- **Key Secret**: `sbD3JVTl7W7UJ18O43cRmtCE`

## Features Implemented

### 1. **Razorpay Service** (`lib/core/services/razorpay_service.dart`)
- Handles all Razorpay payment operations
- Manages payment success, failure, and external wallet callbacks
- Stores payment transactions in Firestore
- Automatically adds credits after successful payment

### 2. **Updated Subscription Controller** (`lib/modules/subscription/subscription_controller.dart`)
- Integrated Razorpay checkout flow
- Shows confirmation dialog before payment
- Handles loading states during payment

### 3. **Updated Subscription View** (`lib/modules/subscription/subscription_view.dart`)
- Added loading overlay during payment processing
- Shows current credit balance
- Displays credit package with pricing

### 4. **Payment Tracking**
All payments are stored in Firestore under:
```
users/{userId}/payments/{paymentId}
```

Payment document structure:
```json
{
  "paymentId": "pay_xxxxx",
  "orderId": "order_xxxxx",
  "signature": "signature_xxxxx",
  "credits": 1000,
  "amount": 200,
  "status": "success" | "failed",
  "errorCode": "error_code",
  "errorMessage": "error_message",
  "timestamp": "timestamp",
  "platform": "razorpay"
}
```

## Testing the Integration

### Test Cards for Payment

#### ✅ **Success Card**
- **Card Number**: `4111 1111 1111 1111`
- **CVV**: Any 3 digits (e.g., `123`)
- **Expiry**: Any future date (e.g., `12/25`)

#### ❌ **Failure Card**
- **Card Number**: `4111 1111 1111 1112`
- **CVV**: Any 3 digits
- **Expiry**: Any future date

#### 🏦 **Other Test Cards**
- **Mastercard**: `5555 5555 5555 4444`
- **Rupay**: `6522 2100 0000 0000`
- **American Express**: `3782 822463 10005`

### Testing Steps

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Navigate to Buy Credits**:
   - Login to the app
   - Go to Profile
   - Tap on "Buy Credits"

3. **Purchase Credits**:
   - Tap "Buy Now" on the 1000 Credits package
   - Confirm the purchase
   - Enter test card details
   - Complete payment

4. **Verify Success**:
   - Check if credits are added to your account
   - View payment record in Firestore Console
   - Check transaction history

### Payment Flow

```
User clicks "Buy Now"
    ↓
Confirmation Dialog
    ↓
User confirms
    ↓
Razorpay Checkout Opens
    ↓
User enters card details
    ↓
Payment Processing
    ↓
Success → Credits Added + Firestore Updated
    OR
Failure → Error Message + Failure Logged
```

## Important Notes

### 🔒 **Security**
- Test keys are used (prefix: `rzp_test_`)
- For production, replace with live keys (prefix: `rzp_live_`)
- Never commit live keys to version control
- Use environment variables for production keys

### 📱 **Platform Support**
- ✅ Android (Fully configured - Razorpay plugin handles manifest automatically)
- ⚠️ iOS (Requires additional setup)
- ❌ Web (Not supported by razorpay_flutter)

**Note**: The Razorpay Flutter plugin automatically includes the necessary Android configuration (CheckoutActivity). No manual manifest changes are required.

### 🍎 **iOS Setup** (If needed)
Add to `ios/Podfile`:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

## Production Checklist

Before going live with real payments:

- [ ] Replace test keys with live Razorpay keys
- [ ] Set up Razorpay webhooks for server-side verification
- [ ] Implement payment signature verification
- [ ] Add server-side payment validation
- [ ] Set up proper error logging and monitoring
- [ ] Test with real payment amounts
- [ ] Add refund handling (if needed)
- [ ] Update terms and privacy policy
- [ ] Enable GST/Tax handling (if applicable)
- [ ] Set up payment reconciliation

## Troubleshooting

### Payment not opening?
- Check internet connection
- Verify Razorpay keys are correct
- Check Android manifest configuration
- Ensure user is logged in

### Credits not added after payment?
- Check Firestore rules allow write access
- Verify user document exists
- Check console logs for errors
- Verify payment callback is triggered

### App crashes on payment?
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app
- Check Android ProGuard rules

## Support

For Razorpay-specific issues:
- [Razorpay Documentation](https://razorpay.com/docs/)
- [Razorpay Flutter Plugin](https://pub.dev/packages/razorpay_flutter)
- [Razorpay Support](https://razorpay.com/support/)

## File Structure

```
lib/
├── core/
│   └── services/
│       ├── credits_service.dart      # Credit management
│       └── razorpay_service.dart     # NEW: Razorpay integration
└── modules/
    └── subscription/
        ├── subscription_controller.dart  # UPDATED: Payment flow
        └── subscription_view.dart        # UPDATED: UI with loading
```

## Additional Features to Consider

1. **Multiple Credit Packages**
   - Add more credit packages (500, 2000, 5000 credits)
   - Implement bulk discount pricing

2. **Payment History**
   - Create a screen to view past transactions
   - Add filters and search functionality

3. **Subscription Plans**
   - Monthly/Yearly subscription with unlimited credits
   - Auto-renewal handling

4. **Promotional Codes**
   - Discount codes for special offers
   - Referral credits

5. **Payment Methods**
   - UPI integration
   - Wallet support (Paytm, PhonePe, etc.)
   - Net banking

---

**Last Updated**: February 28, 2026
**Version**: 1.0.0
