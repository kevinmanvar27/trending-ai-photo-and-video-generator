# Play Store Assets - Quick Reference

## 📱 Required Sizes & Formats

### 1. App Icon
- **Size:** 512 x 512 px
- **Format:** 32-bit PNG (with alpha)
- **No transparency in background**
- **File name:** `app_icon_512.png`

### 2. Feature Graphic
- **Size:** 1024 x 500 px
- **Format:** PNG or JPEG
- **File name:** `feature_graphic.png`
- **Purpose:** Displayed at top of store listing

### 3. Phone Screenshots (REQUIRED - Minimum 2)
- **Size:** 1080 x 1920 px (16:9 ratio)
- **Alternative:** 1080 x 2340 px (19.5:9 ratio)
- **Format:** PNG or JPEG
- **Minimum:** 2 screenshots
- **Maximum:** 8 screenshots
- **File names:** `screenshot_phone_1.png`, `screenshot_phone_2.png`, etc.

**Recommended Screenshots:**
1. **Home/Templates Screen** - Show variety of templates
2. **Upload Screen** - Show easy upload process
3. **Processing Screen** - Show AI processing
4. **Result Screen** - Show beautiful generated output
5. **Profile Screen** - Show subscription/coins
6. **Referral Screen** - Show earning opportunities

### 4. Tablet Screenshots (OPTIONAL)
- **7-inch:** 1200 x 1920 px
- **10-inch:** 2048 x 2732 px
- **Format:** PNG or JPEG

### 5. Promo Video (OPTIONAL but Recommended)
- **Platform:** YouTube
- **Duration:** 30 seconds to 2 minutes
- **Content:** App demo, features showcase
- **Aspect Ratio:** 16:9

---

## 🎨 Design Guidelines

### App Icon
- Clear and recognizable
- Represents AI/Photo/Video concept
- Looks good at small sizes
- Follows Material Design guidelines
- No text or small details

### Feature Graphic
- Eye-catching banner
- Shows app name/logo
- Highlights key features
- Professional design
- No important content in edges (safe zone)

### Screenshots
- Show actual app UI (no mockups)
- Use real/sample content
- Add captions/text overlays (optional)
- Show key features
- Consistent style across all screenshots
- High quality, no blur or pixelation

---

## 📝 Text Content Limits

| Item | Character Limit |
|------|----------------|
| App Name | 50 characters |
| Short Description | 80 characters |
| Full Description | 4,000 characters |
| Recent Changes | 500 characters |
| Developer Name | 50 characters |

---

## 🔢 Version Information

### Version Name
- Format: `MAJOR.MINOR.PATCH`
- Example: `1.0.0`
- User-visible version

### Version Code
- Integer that increases with each release
- Example: `1`, `2`, `3`, etc.
- Not visible to users

**In `pubspec.yaml`:**
```yaml
version: 1.0.0+1
         ↑     ↑
    Version  Version
     Name     Code
```

---

## 🌍 Localization (Optional)

If supporting multiple languages:

### Translate:
- App name
- Short description
- Full description
- Screenshots (with localized UI)

### Supported Languages:
- English (default)
- Spanish
- French
- German
- Hindi
- And more...

---

## 💡 Tips for Better Visibility

### ASO (App Store Optimization)

**Title Optimization:**
- Include main keywords
- Keep it clear and concise
- Example: "Trends - AI Photo & Video"

**Description Optimization:**
- Use keywords naturally
- Highlight unique features
- Include benefits, not just features
- Use bullet points for readability
- Add social proof (if available)

**Keywords to Include:**
- AI photo editor
- AI video maker
- Photo effects
- Video effects
- AI art generator
- Photo enhancer
- Video editor
- AI filters
- Content creator
- Instagram
- TikTok

**Screenshots Optimization:**
- First 2-3 screenshots are most important
- Show your best features first
- Use captions to explain features
- Show results/benefits

---

## 📊 Content Rating

### Questionnaire Topics:
1. **Violence** - None
2. **Sexual Content** - None
3. **Profanity** - None
4. **Controlled Substances** - None
5. **Gambling** - None
6. **User-Generated Content** - Yes (photos/videos uploaded by users)

### Expected Rating:
- **Everyone** or **Teen (13+)**

---

## 🔐 Data Safety Section

### Data Collected:
- Email address
- Name (optional)
- Phone number
- Photos and videos
- Device contacts (with permission)
- Usage data

### Data Usage:
- App functionality
- Analytics
- Personalization
- Communication

### Data Sharing:
- Firebase (Google) - Authentication, Storage, Analytics
- Razorpay - Payment processing
- AI Processing Servers

### Security:
- Data encrypted in transit (HTTPS)
- Secure authentication
- User can delete data

---

## 🚀 Release Build Commands

### Build AAB (App Bundle - Recommended)
```bash
flutter build appbundle --release
```
**Output:** `build/app/outputs/bundle/release/app-release.aab`

### Build APK (For Testing)
```bash
flutter build apk --release
```
**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### Build Split APKs
```bash
flutter build apk --split-per-abi --release
```

---

## 📁 Asset Organization

```
playstore/
├── assets/
│   ├── app_icon_512.png
│   ├── feature_graphic.png
│   ├── screenshots/
│   │   ├── phone/
│   │   │   ├── screenshot_1.png
│   │   │   ├── screenshot_2.png
│   │   │   ├── screenshot_3.png
│   │   │   └── screenshot_4.png
│   │   └── tablet/ (optional)
│   └── promo_video_link.txt
├── APP_NAME.md
├── SHORT_DESCRIPTION.md
├── LONG_DESCRIPTION.md
├── PRIVACY_POLICY.md
├── TERMS_AND_CONDITIONS.md
└── SUBMISSION_CHECKLIST.md
```

---

## ⏱️ Timeline Estimate

| Stage | Duration |
|-------|----------|
| Asset Preparation | 1-2 days |
| Privacy Policy/ToC | 1 day |
| Internal Testing | 1-2 weeks |
| Closed Testing | 2-4 weeks |
| Review Process | 1-7 days |
| **Total** | **4-7 weeks** |

---

## 📞 Important Links

- **Google Play Console:** https://play.google.com/console
- **Developer Policy:** https://play.google.com/about/developer-content-policy/
- **App Quality Guidelines:** https://developer.android.com/quality
- **Material Design:** https://material.io/design

---

## ✅ Pre-Submission Checklist

- [ ] All assets created and optimized
- [ ] Privacy policy hosted publicly
- [ ] Terms & conditions hosted publicly
- [ ] App tested on multiple devices
- [ ] No crashes or critical bugs
- [ ] All features working
- [ ] Store listing completed
- [ ] Content rating done
- [ ] Data safety section filled
- [ ] Release build signed
- [ ] Ready to submit!

---

**Need help? Contact: support@rektech.work**
