# 🎯 Quick Test Guide - Razorpay Integration

## ⚡ Test in 5 Minutes!

### 📱 Step-by-Step Visual Guide

```
┌─────────────────────────────────────────┐
│  1. Open App → Login with Google       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  2. Tap "Profile" (bottom navigation)   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  3. Scroll down → Tap "Buy Credits"     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  4. You'll see:                         │
│     ┌─────────────────────────────┐     │
│     │  Current Balance: X Credits │     │
│     └─────────────────────────────┘     │
│     ┌─────────────────────────────┐     │
│     │   🔥 BEST VALUE             │     │
│     │   ⭐ 1000 Credits            │     │
│     │   ₹200                       │     │
│     │   [Buy Now]                 │     │
│     └─────────────────────────────┘     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  5. Tap "Buy Now"                       │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  6. Confirm Purchase Dialog:            │
│     "Buy 1000 credits for ₹200?"        │
│     [Cancel] [Proceed to Pay]           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  7. Razorpay Checkout Opens!            │
│     ┌─────────────────────────────┐     │
│     │ Trends App                  │     │
│     │ 1000 Credits                │     │
│     │ ₹200                         │     │
│     │                             │     │
│     │ Card Number: ______________ │     │
│     │ Expiry: __/__  CVV: ___    │     │
│     │ Name: ___________________  │     │
│     │                             │     │
│     │ [Pay ₹200]                  │     │
│     └─────────────────────────────┘     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  8. Enter Test Card:                    │
│     Card: 4111 1111 1111 1111           │
│     Expiry: 12/25                       │
│     CVV: 123                            │
│     Name: Test User                     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  9. Tap "Pay ₹200"                      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  10. ✅ SUCCESS!                         │
│      "Payment Successful!"              │
│      "You received 1000 credits"        │
│      → Back to Profile                  │
│      → Credits Updated!                 │
└─────────────────────────────────────────┘
```

---

## 💳 Test Cards

### ✅ Success Card
```
Card Number: 4111 1111 1111 1111
CVV: 123
Expiry: 12/25
Name: Any name
```

### ❌ Failure Card (to test error handling)
```
Card Number: 4111 1111 1111 1112
CVV: 123
Expiry: 12/25
Name: Any name
```

---

## 🎬 What Happens After Payment?

### On Success:
1. ✅ Credits added to your account
2. ✅ Success message: "Payment Successful! You received 1000 credits"
3. ✅ Navigate back to Profile
4. ✅ Payment saved in Firestore: `users/{userId}/payments/`
5. ✅ Transaction logged: `users/{userId}/transactions/`

### On Failure:
1. ❌ Error message: "Payment Failed - [error message]"
2. ❌ No credits added
3. ❌ Failure logged in Firestore for tracking

---

## 🔍 Verify Payment in Firebase

1. Go to: https://console.firebase.google.com/
2. Select: **Trends** project
3. Navigate: **Firestore Database**
4. Path: `users/{your-user-id}/payments/`
5. You'll see:
   ```json
   {
     "paymentId": "pay_xxxxx",
     "credits": 1000,
     "amount": 200,
     "status": "success",
     "timestamp": "..."
   }
   ```

---

## 🚨 Common Issues & Quick Fixes

### Issue: "Buy Credits" button not visible?
**Fix:** Scroll down on the Profile screen

### Issue: Payment screen not opening?
**Fix:** 
1. Check internet connection
2. Make sure you're logged in
3. Restart the app

### Issue: Credits not added after payment?
**Fix:**
1. Pull down to refresh on Profile screen
2. Check Firestore console
3. Check app logs

---

## 📊 Current Configuration

- **Package**: 1000 Credits for ₹200
- **Price per credit**: ₹0.20
- **Mode**: Test (using test keys)
- **Platform**: Android ✅

---

## 🎯 Quick Commands

### Run the app:
```bash
flutter run
```

### Check logs:
```bash
flutter logs
```

### Rebuild if needed:
```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Test Checklist

Quick checklist to verify everything:

- [ ] App opens successfully
- [ ] Can login with Google
- [ ] Profile screen loads
- [ ] "Buy Credits" button visible
- [ ] Buy Credits screen opens
- [ ] Current balance displays
- [ ] Credit package shows correctly
- [ ] "Buy Now" button works
- [ ] Confirmation dialog appears
- [ ] Razorpay checkout opens
- [ ] Can enter card details
- [ ] Payment processes
- [ ] Success message appears
- [ ] Credits added to account
- [ ] Payment in Firestore

---

## 🎊 You're All Set!

Everything is configured and ready to test. Just follow the steps above and you'll see Razorpay in action!

**Need help?** Check:
- `RAZORPAY_INTEGRATION.md` - Detailed documentation
- `RAZORPAY_SUMMARY.md` - Complete overview
- Console logs - For debugging

---

**Happy Testing! 🚀**
