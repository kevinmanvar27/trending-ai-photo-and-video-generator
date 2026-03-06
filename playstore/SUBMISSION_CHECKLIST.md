# Google Play Store Submission Checklist

## ✅ App Information

### Basic Details
- [x] **App Name:** Trends - AI Photo & Video
- [x] **Package Name:** com.rektech.trends
- [x] **Category:** Photography / Art & Design
- [x] **Content Rating:** Everyone (13+)
- [x] **Privacy Policy URL:** https://trends.rektech.work/privacy-policy
- [x] **Terms & Conditions URL:** https://trends.rektech.work/terms

### Short Description (80 chars max)
```
Transform photos & videos with AI. Create stunning content in seconds! ✨
```

### Full Description (4000 chars max)
See: `LONG_DESCRIPTION.md`

---

## 📱 App Assets Required

### App Icon
- **Size:** 512 x 512 px
- **Format:** PNG (32-bit with alpha)
- **No transparency**
- **File:** `playstore/assets/app_icon_512.png`

### Feature Graphic
- **Size:** 1024 x 500 px
- **Format:** PNG or JPEG
- **File:** `playstore/assets/feature_graphic.png`

### Screenshots (Required: Minimum 2, Maximum 8)

**Phone Screenshots (Required)**
- **Size:** 1080 x 1920 px or 1080 x 2340 px
- **Format:** PNG or JPEG
- **Minimum:** 2 screenshots
- **Recommended:** 4-8 screenshots

Screenshots to include:
1. Home screen with templates
2. Template selection screen
3. Upload/processing screen
4. Generated result preview
5. Profile/subscription screen
6. Referral screen (optional)

**Tablet Screenshots (Optional)**
- **Size:** 1200 x 1920 px or 2048 x 2732 px

### Video (Optional but Recommended)
- **YouTube URL:** Promo video showing app features
- **Duration:** 30 seconds to 2 minutes
- **Content:** App walkthrough, features demo

---

## 🔐 App Signing & Build

### Release Build
```bash
flutter build appbundle --release
```
**Output:** `build/app/outputs/bundle/release/app-release.aab`

### App Signing
- [ ] Create upload keystore
- [ ] Configure key.properties
- [ ] Sign the AAB with keystore
- [ ] Enable Google Play App Signing

### Version Information
- **Version Name:** 1.0.0
- **Version Code:** 1

---

## 📋 Store Listing Details

### Contact Details
- **Email:** support@rektech.work
- **Phone:** [Your Phone Number] (optional)
- **Website:** https://trends.rektech.work

### Developer Account
- **Developer Name:** RekTech
- **Developer Address:** [Your Complete Address]

### Privacy & Security

**Privacy Policy** (Required)
- URL: https://trends.rektech.work/privacy-policy
- Must be hosted publicly
- Must be accessible without login

**Data Safety Section** (Required)
Answer questions about:
- Data collection (Email, Phone, Photos, Videos, Contacts)
- Data usage (App functionality, Analytics, Personalization)
- Data sharing (Third-party services: Firebase, Razorpay)
- Data security (Encryption in transit, User controls)

**Permissions Used:**
- READ_CONTACTS - "To help you find and invite friends"
- WRITE_CONTACTS - "To manage contact sync"
- INTERNET - "To process photos/videos and sync data"
- READ_EXTERNAL_STORAGE - "To access photos/videos"
- WRITE_EXTERNAL_STORAGE - "To save generated content"
- CAMERA - "To capture photos/videos" (if applicable)

---

## 💰 Pricing & Distribution

### Pricing
- [x] Free app with in-app purchases
- [x] In-app products configured:
  - Coin packages
  - Subscription plans (monthly, yearly)

### Countries
- [x] All countries (or select specific countries)

### Content Rating
Fill out content rating questionnaire:
- Violence: None
- Sexual Content: None
- Profanity: None
- Controlled Substances: None
- Gambling: None
- User-Generated Content: Yes (photos/videos)

Expected Rating: **Everyone** or **Teen** (13+)

---

## 🧪 Testing

### Pre-Launch Checklist
- [ ] Test on multiple devices (phones & tablets)
- [ ] Test on different Android versions (minimum API 21)
- [ ] Test all features:
  - [ ] Login/Registration
  - [ ] Photo upload & processing
  - [ ] Video upload & processing
  - [ ] Template selection
  - [ ] Coin system
  - [ ] Subscription purchase
  - [ ] Referral system
  - [ ] Contact sync
  - [ ] Profile management
  - [ ] Dark mode
- [ ] Test payment flows (sandbox mode)
- [ ] Check for crashes and ANRs
- [ ] Verify privacy policy and ToC links work

### Google Play Console Tests
- [ ] Pre-launch report (automatic testing)
- [ ] Internal testing track
- [ ] Closed testing (alpha/beta)
- [ ] Open testing (optional)

---

## 📝 App Content

### App Category
- **Primary:** Photography
- **Secondary:** Art & Design (optional)

### Tags/Keywords
```
AI photo editor, AI video maker, photo effects, video effects, AI art, 
photo enhancer, video editor, AI filters, creative templates, 
photo transformation, AI creator, content creator, Instagram, TikTok
```

### Target Audience
- Age: 13+
- Interest: Photography, Video Editing, Social Media, Content Creation

---

## 🚀 Release Strategy

### Release Tracks

**Internal Testing** (First)
- Small group of testers
- Quick feedback and bug fixes
- Duration: 1-2 weeks

**Closed Testing** (Second)
- Larger group (100-1000 users)
- Beta testers via email list
- Duration: 2-4 weeks

**Open Testing** (Optional)
- Public beta
- Anyone can join
- Duration: 1-2 weeks

**Production** (Final)
- Full public release
- Staged rollout recommended (10% → 50% → 100%)

---

## 📊 Post-Launch

### Monitor
- [ ] Crash reports (Firebase Crashlytics)
- [ ] User reviews and ratings
- [ ] Download statistics
- [ ] Revenue metrics
- [ ] User retention

### Respond
- [ ] Reply to user reviews
- [ ] Fix critical bugs quickly
- [ ] Release updates regularly
- [ ] Add requested features

### Optimize
- [ ] A/B test store listing
- [ ] Update screenshots based on performance
- [ ] Optimize keywords for ASO
- [ ] Run promotional campaigns

---

## 🔗 Important Links

### Documentation
- Privacy Policy: `playstore/PRIVACY_POLICY.md`
- Terms & Conditions: `playstore/TERMS_AND_CONDITIONS.md`
- App Description: `playstore/LONG_DESCRIPTION.md`

### Build Commands
```bash
# Clean build
flutter clean
flutter pub get

# Build AAB (Release)
flutter build appbundle --release

# Build APK (Testing)
flutter build apk --release
```

### Google Play Console
- URL: https://play.google.com/console
- Developer Account: [Your Account]

---

## ⚠️ Common Rejection Reasons (Avoid These)

1. **Privacy Policy Issues**
   - Missing or inaccessible privacy policy
   - Privacy policy doesn't match app functionality
   - Not explaining data collection clearly

2. **Permissions Issues**
   - Requesting unnecessary permissions
   - Not explaining permission usage
   - Dangerous permissions without justification

3. **Content Issues**
   - Inappropriate content
   - Misleading description or screenshots
   - Copyrighted material without permission

4. **Technical Issues**
   - App crashes on launch
   - Core functionality doesn't work
   - Poor performance or ANRs

5. **Policy Violations**
   - Spam or misleading behavior
   - Inappropriate ads
   - Violating Google Play policies

---

## 📞 Support & Resources

### Google Play Console Help
- https://support.google.com/googleplay/android-developer

### Flutter Release Guide
- https://docs.flutter.dev/deployment/android

### App Signing
- https://developer.android.com/studio/publish/app-signing

### Content Rating
- https://support.google.com/googleplay/android-developer/answer/9859655

---

## ✅ Final Checklist Before Submission

- [ ] App builds successfully (AAB)
- [ ] All features tested and working
- [ ] Privacy policy uploaded and accessible
- [ ] Terms & conditions uploaded and accessible
- [ ] All required assets prepared (icon, screenshots, feature graphic)
- [ ] Store listing completed (descriptions, categories, tags)
- [ ] Content rating questionnaire completed
- [ ] Data safety section completed
- [ ] Payment/subscription configured (if applicable)
- [ ] Developer account verified
- [ ] App signed with upload key
- [ ] Internal testing completed successfully

---

**Good luck with your Play Store submission! 🚀**
