# Closet R13 — Polish & App Store Launch

## Goal
Ship Closet 1.0 to the App Store with a polished, professional presentation.

---

## Pre-Launch Checklist

### 1. App Store Assets
- [ ] **App Icon:** 1024×1024 master icon (hanger + sparkles motif)
- [ ] **Screenshots:** 6.7" (iPhone 16 Pro), 6.5" (iPhone 14 Pro Max), iPad Pro 12.9"
  - Wardrobe grid, outfit builder, style profile, calendar log
- [ ] **App Preview Video:** 30s walkthrough (add item → generate outfit → log worn)
- [ ] **Description:** 170 chars (short) + full description (3800 chars)
- [ ] **Keywords:** 100 char limit — "wardrobe, outfit, style, fashion, closet, tracker, stylist"

### 2. Marketing Copy
- **Tagline:** "Your AI-Powered Personal Stylist"
- **Subtitle:** "Transform your wardrobe into an intelligent style system"
- **Feature bullets (3):**
  - "Snap & catalog your entire wardrobe instantly"
  - "Get smart outfit suggestions based on weather & occasion"
  - "Track your style profile and most-worn pieces"

### 3. Legal & Compliance
- [ ] Privacy Policy URL (required)
- [ ] Terms of Service URL
- [ ] Age Rating: 4+ (minimal permissions)
- [ ] Export Compliance: No cryptographic functions
- [ ] Ads: App does not contain ads
- [ ] Content: App does not filter user-generated content

### 4. Build Configuration
- [ ] Bundle ID: `com.closet.stylist` (iOS), `com.tommaso.closet.mac` (macOS)
- [ ] App Category: Lifestyle
- [ ] Pricing: Free (no IAP in 1.0)
- [ ] Build numbers match between iOS + macOS
- [ ] TestFlight: Upload iOS build, add external testers
- [ ] Notarization: macOS app notarized with Apple Developer certificate

### 5. Testing
- [ ] **iOS 26** on iPhone 16 Pro simulator
- [ ] **macOS 15.0** on Apple Silicon Mac
- [ ] Camera + photo library permissions work correctly
- [ ] Empty states display properly
- [ ] All navigation flows work
- [ ] No crashes on cold start

---

## Polish Tasks

### UI Polish
- [ ] Consistent corner radius: 12pt for cards, 8pt for buttons
- [ ] Typography: New York for headings (serif), SF Pro for body
- [ ] Color palette finalization and named colors in code
- [ ] Empty state illustrations (SVG, vector)
- [ ] Loading shimmer animation for images
- [ ] Haptic feedback on save/like actions

### Animation Polish
- [ ] Spring-based card transitions (0.3-0.4s)
- [ ] Swipe-to-dismiss on outfit cards
- [ ] Fade + scale on navigation pushes
- [ ] Tab switching animation

### Accessibility
- [ ] VoiceOver labels on all interactive elements
- [ ] Dynamic Type support (scaled fonts)
- [ ] Minimum tap target: 44×44pt
- [ ] Color contrast ratio ≥ 4.5:1

### Performance
- [ ] Image loading: Lazy load, downsample thumbnails to 200px
- [ ] Grid scroll: 60fps with 100+ items
- [ ] App launch: <2s to interactive

---

## Launch Day

### Go-Live Steps
1. Submit for App Review (5-7 business days typically)
2. Enable "Release" after approval
3. Announce on social media / personal network
4. Submit to Product Hunt
5. Monitor App Store Connect for crash reports

### Post-Launch Monitoring
- Crashlytics / Firebase Crash Reporting
- App Store reviews + responses
- Weekly analytics review (if Firebase Analytics added)

---

## Future Roadmap (Post-1.0)
- Closet 2.0: CloudKit sync + sharing (R12)
- Closet 2.1: Apple Watch companion app
- Closet 2.2: Siri Shortcuts integration
- Closet 3.0: VisionKit for automatic clothing detection
